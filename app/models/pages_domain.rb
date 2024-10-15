# frozen_string_literal: true

class PagesDomain < ApplicationRecord
  include Presentable
  include FromUnion
  include AfterCommitQueue

  VERIFICATION_KEY = 'gitlab-pages-verification-code'
  VERIFICATION_THRESHOLD = 3.days.freeze
  SSL_RENEWAL_THRESHOLD = 30.days.freeze

  MAX_CERTIFICATE_KEY_LENGTH = 8192

  X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN = 19

  enum certificate_source: { user_provided: 0, gitlab_provided: 1 }, _prefix: :certificate
  enum scope: { instance: 0, group: 1, project: 2 }, _prefix: :scope, _default: :project
  enum usage: { pages: 0, serverless: 1 }, _prefix: :usage, _default: :pages

  belongs_to :project
  has_many :acme_orders, class_name: "PagesDomainAcmeOrder"

  after_initialize :set_verification_code
  before_validation :clear_auto_ssl_failure, unless: :auto_ssl_enabled

  validates :project, presence: true
  validates :domain, hostname: { allow_numeric_hostname: true }
  validates :domain, uniqueness: { case_sensitive: false }
  validates :certificate, :key, presence: true, if: :usage_serverless?
  validates :certificate, presence: { message: 'must be present if HTTPS-only is enabled' },
    if: :certificate_should_be_present?
  validates :certificate, certificate: true, if: ->(domain) { domain.certificate.present? }
  validates :key, presence: { message: 'must be present if HTTPS-only is enabled' },
    if: :certificate_should_be_present?
  validates :key, certificate_key: true, named_ecdsa_key: true, if: ->(domain) { domain.key.present? }
  validates :verification_code, presence: true, allow_blank: false

  validate :validate_pages_domain
  validate :max_certificate_key_length, if: ->(domain) { domain.key.present? }
  validate :validate_matching_key, if: ->(domain) { domain.certificate.present? || domain.key.present? }
  # validate_intermediates must run after key validations to skip expensive SSL validation when there is a key error
  validate :validate_intermediates, if: ->(domain) { domain.certificate.present? && domain.certificate_changed? && errors[:key].blank? }
  validate :validate_custom_domain_count_per_project, on: :create

  attribute :auto_ssl_enabled, default: -> { ::Gitlab::LetsEncrypt.enabled? }
  attribute :wildcard, default: false

  attr_encrypted :key,
    mode: :per_attribute_iv_and_salt,
    insecure_mode: true,
    key: Settings.attr_encrypted_db_key_base,
    algorithm: 'aes-256-cbc'

  scope :for_project, ->(project) { where(project: project) }

  scope :enabled, -> { where('enabled_until >= ?', Time.current) }
  scope :needs_verification, -> do
    verified_at = arel_table[:verified_at]
    enabled_until = arel_table[:enabled_until]
    threshold = Time.current + VERIFICATION_THRESHOLD

    where(verified_at.eq(nil).or(enabled_until.eq(nil).or(enabled_until.lt(threshold))))
  end
  scope :verified, -> { where.not(verified_at: nil) }

  scope :need_auto_ssl_renewal, -> do
    enabled_and_not_failed = where(auto_ssl_enabled: true, auto_ssl_failed: false)

    user_provided = enabled_and_not_failed.certificate_user_provided
    certificate_not_valid = enabled_and_not_failed.where(certificate_valid_not_after: nil)
    certificate_expiring = enabled_and_not_failed
                             .where(arel_table[:certificate_valid_not_after].lt(SSL_RENEWAL_THRESHOLD.from_now))

    from_union([user_provided, certificate_not_valid, certificate_expiring])
  end

  scope :for_removal, -> { where("remove_at < ?", Time.current) }

  scope :with_logging_info, -> { includes(project: [:namespace, :route]) }

  scope :instance_serverless, -> { where(wildcard: true, scope: :instance, usage: :serverless) }

  def self.find_by_domain_case_insensitive(domain)
    find_by("LOWER(domain) = LOWER(?)", domain)
  end

  def self.ids_for_project(project_id)
    where(project_id: project_id).ids
  end

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

  def has_valid_intermediates?
    return false unless x509

    # self-signed certificates don't have the certificate chain
    return true if x509.verify(x509.public_key)

    store = OpenSSL::X509::Store.new
    store.set_default_paths

    store.verify_callback = ->(is_valid, store_ctx) {
      # allow self signed certs, see https://gitlab.com/gitlab-org/gitlab/-/issues/356447
      return true if store_ctx.error == X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN

      self.errors.add(:certificate, store_ctx.error_string) unless is_valid
      is_valid
    }

    store.verify(x509, untrusted_ca_certs_bundle)
  rescue OpenSSL::X509::StoreError
    false
  end

  def untrusted_ca_certs_bundle
    ::Gitlab::X509::Certificate.load_ca_certs_bundle(certificate)
  end

  def expired?
    return false unless x509

    current = Time.current
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

  def verification_record
    "#{verification_domain} TXT #{keyed_verification_code}"
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
    self.certificate_source = 'user_provided' if attribute_changed?(:key)
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
    self.certificate_source = 'gitlab_provided' if attribute_changed?(:key)
  end

  def clear_auto_ssl_failure
    self.auto_ssl_failed = false
  end

  def validate_custom_domain_count_per_project
    return unless project

    unless project.can_create_custom_domains?
      self.errors.add(
        :base,
        _("This project reached the limit of custom domains. (Max %d)") % Gitlab::CurrentSettings.max_pages_custom_domains_per_project)
    end
  end

  def pages_deployed?
    project&.pages_deployed?
  end

  private

  def max_certificate_key_length
    return unless pkey.is_a?(OpenSSL::PKey::RSA)
    return if pkey.to_s.bytesize <= MAX_CERTIFICATE_KEY_LENGTH

    errors.add(
      :key,
      s_("PagesDomain|Certificate Key is too long. (Max %d bytes)") % MAX_CERTIFICATE_KEY_LENGTH
    )
  end

  def set_verification_code
    return if self.verification_code.present?

    self.verification_code = SecureRandom.hex(16)
  end

  def validate_matching_key
    unless has_matching_key?
      self.errors.add(:key, "doesn't match the certificate")
    end
  end

  def validate_intermediates
    self.errors.add(:certificate, 'misses intermediates') unless has_valid_intermediates?
  end

  def validate_pages_domain
    return unless domain

    if domain.downcase.ends_with?(".#{Settings.pages.host.downcase}")
      error_template = _("Subdomains of the Pages root domain %{root_domain} are reserved and cannot be used as custom Pages domains.")
      self.errors.add(:domain, error_template % { root_domain: Settings.pages.host })
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

PagesDomain.prepend_mod_with('PagesDomain')
