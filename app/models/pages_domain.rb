# frozen_string_literal: true

class PagesDomain < ApplicationRecord
  VERIFICATION_KEY = 'gitlab-pages-verification-code'
  VERIFICATION_THRESHOLD = 3.days.freeze
  SSL_RENEWAL_THRESHOLD = 30.days.freeze

  enum certificate_source: { user_provided: 0, gitlab_provided: 1 }, _prefix: :certificate
  enum domain_type: { instance: 0, group: 1, project: 2 }, _prefix: :domain_type

  belongs_to :project
  has_many :acme_orders, class_name: "PagesDomainAcmeOrder"

  validates :domain, hostname: { allow_numeric_hostname: true }
  validates :domain, uniqueness: { case_sensitive: false }
  validates :certificate, presence: { message: 'must be present if HTTPS-only is enabled' },
            if: :certificate_should_be_present?
  validates :certificate, certificate: true, if: ->(domain) { domain.certificate.present? }
  validates :key, presence: { message: 'must be present if HTTPS-only is enabled' },
            if: :certificate_should_be_present?
  validates :key, certificate_key: true, named_ecdsa_key: true, if: ->(domain) { domain.key.present? }
  validates :verification_code, presence: true, allow_blank: false

  validate :validate_pages_domain
  validate :validate_matching_key, if: ->(domain) { domain.certificate.present? || domain.key.present? }
  validate :validate_intermediates, if: ->(domain) { domain.certificate.present? && domain.certificate_changed? }

  default_value_for(:auto_ssl_enabled, allow_nil: false) { ::Gitlab::LetsEncrypt.enabled? }
  default_value_for :domain_type, allow_nil: false, value: :project
  default_value_for :wildcard, allow_nil: false, value: false

  attr_encrypted :key,
    mode: :per_attribute_iv_and_salt,
    insecure_mode: true,
    key: Settings.attr_encrypted_db_key_base,
    algorithm: 'aes-256-cbc'

  after_initialize :set_verification_code
  after_create :update_daemon
  after_update :update_daemon, if: :saved_change_to_pages_config?
  after_destroy :update_daemon

  scope :enabled, -> { where('enabled_until >= ?', Time.now ) }
  scope :needs_verification, -> do
    verified_at = arel_table[:verified_at]
    enabled_until = arel_table[:enabled_until]
    threshold = Time.now + VERIFICATION_THRESHOLD

    where(verified_at.eq(nil).or(enabled_until.eq(nil).or(enabled_until.lt(threshold))))
  end

  scope :need_auto_ssl_renewal, -> do
    expiring = where(certificate_valid_not_after: nil).or(
      where(arel_table[:certificate_valid_not_after].lt(SSL_RENEWAL_THRESHOLD.from_now)))

    user_provided_or_expiring = certificate_user_provided.or(expiring)

    where(auto_ssl_enabled: true).merge(user_provided_or_expiring)
  end

  scope :for_removal, -> { where("remove_at < ?", Time.now) }

  def verified?
    !!verified_at
  end

  def unverified?
    !verified?
  end

  def enabled?
    !Gitlab::CurrentSettings.pages_domain_verification_enabled? || enabled_until.present?
  end

  def https?
    certificate.present?
  end

  def to_param
    domain
  end

  def url
    return unless domain

    if certificate.present?
      "https://#{domain}"
    else
      "http://#{domain}"
    end
  end

  def has_matching_key?
    return false unless x509
    return false unless pkey

    # We compare the public key stored in certificate with public key from certificate key
    x509.check_private_key(pkey)
  end

  def has_intermediates?
    return false unless x509

    # self-signed certificates doesn't have the certificate chain
    return true if x509.verify(x509.public_key)

    store = OpenSSL::X509::Store.new
    store.set_default_paths

    # This forces to load all intermediate certificates stored in `certificate`
    Tempfile.open('certificate_chain') do |f|
      f.write(certificate)
      f.flush
      store.add_file(f.path)
    end

    store.verify(x509)
  rescue OpenSSL::X509::StoreError
    false
  end

  def expired?
    return false unless x509

    current = Time.new
    current < x509.not_before || x509.not_after < current
  end

  def expiration
    x509&.not_after
  end

  def subject
    return unless x509

    x509.subject.to_s
  end

  def certificate_text
    @certificate_text ||= x509.try(:to_text)
  end

  # Verification codes may be TXT records for domain or verification_domain, to
  # support the use of CNAME records on domain.
  def verification_domain
    return unless domain.present?

    "_#{VERIFICATION_KEY}.#{domain}"
  end

  def keyed_verification_code
    return unless verification_code.present?

    "#{VERIFICATION_KEY}=#{verification_code}"
  end

  def certificate=(certificate)
    super(certificate)

    # set nil, if certificate is nil
    self.certificate_valid_not_before = x509&.not_before
    self.certificate_valid_not_after = x509&.not_after
  end

  def user_provided_key
    key if certificate_user_provided?
  end

  def user_provided_key=(key)
    self.key = key
    self.certificate_source = 'user_provided' if key_changed?
  end

  def user_provided_certificate
    certificate if certificate_user_provided?
  end

  def user_provided_certificate=(certificate)
    self.certificate = certificate
    self.certificate_source = 'user_provided' if certificate_changed?
  end

  def gitlab_provided_certificate=(certificate)
    self.certificate = certificate
    self.certificate_source = 'gitlab_provided' if certificate_changed?
  end

  def gitlab_provided_key=(key)
    self.key = key
    self.certificate_source = 'gitlab_provided' if key_changed?
  end

  def pages_virtual_domain
    return unless pages_deployed?

    Pages::VirtualDomain.new([project], domain: self)
  end

  private

  def pages_deployed?
    # TODO: remove once `pages_metadatum` is migrated
    # https://gitlab.com/gitlab-org/gitlab/issues/33106
    unless project.pages_metadatum
      Gitlab::BackgroundMigration::MigratePagesMetadata
        .new
        .perform_on_relation(Project.where(id: project_id))

      project.reset
    end

    project.pages_metadatum&.deployed?
  end

  def set_verification_code
    return if self.verification_code.present?

    self.verification_code = SecureRandom.hex(16)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def update_daemon
    return if domain_type_instance?

    ::Projects::UpdatePagesConfigurationService.new(project).execute
  end
  # rubocop: enable CodeReuse/ServiceClass

  def saved_change_to_pages_config?
    saved_change_to_project_id? ||
      saved_change_to_domain? ||
      saved_change_to_certificate? ||
      saved_change_to_key? ||
      became_enabled? ||
      became_disabled?
  end

  def became_enabled?
    enabled_until.present? && !enabled_until_before_last_save.present?
  end

  def became_disabled?
    !enabled_until.present? && enabled_until_before_last_save.present?
  end

  def validate_matching_key
    unless has_matching_key?
      self.errors.add(:key, "doesn't match the certificate")
    end
  end

  def validate_intermediates
    unless has_intermediates?
      self.errors.add(:certificate, 'misses intermediates')
    end
  end

  def validate_pages_domain
    return unless domain

    if domain.downcase.ends_with?(Settings.pages.host.downcase)
      self.errors.add(:domain, "*.#{Settings.pages.host} is restricted")
    end
  end

  def x509
    return unless certificate.present?

    @x509 ||= OpenSSL::X509::Certificate.new(certificate)
  rescue OpenSSL::X509::CertificateError
    nil
  end

  def pkey
    return unless key

    @pkey ||= OpenSSL::PKey.read(key)
  rescue OpenSSL::PKey::PKeyError, OpenSSL::Cipher::CipherError
    nil
  end

  def certificate_should_be_present?
    !auto_ssl_enabled? && project&.pages_https_only?
  end
end
