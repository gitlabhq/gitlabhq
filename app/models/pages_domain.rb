class PagesDomain < ActiveRecord::Base
  VERIFICATION_KEY = 'gitlab-pages-verification-code'.freeze
  VERIFICATION_THRESHOLD = 3.days.freeze

  belongs_to :project

  validates :domain, hostname: { allow_numeric_hostname: true }
  validates :domain, uniqueness: { case_sensitive: false }
  validates :certificate, presence: { message: 'must be present if HTTPS-only is enabled' }, if: ->(domain) { domain.project&.pages_https_only? }
  validates :certificate, certificate: true, if: ->(domain) { domain.certificate.present? }
  validates :key, presence: { message: 'must be present if HTTPS-only is enabled' }, if: ->(domain) { domain.project&.pages_https_only? }
  validates :key, certificate_key: true, if: ->(domain) { domain.key.present? }
  validates :verification_code, presence: true, allow_blank: false

  validate :validate_pages_domain
  validate :validate_matching_key, if: ->(domain) { domain.certificate.present? || domain.key.present? }
  validate :validate_intermediates, if: ->(domain) { domain.certificate.present? }

  attr_encrypted :key,
    mode: :per_attribute_iv_and_salt,
    insecure_mode: true,
    key: Gitlab::Application.secrets.db_key_base,
    algorithm: 'aes-256-cbc'

  after_initialize :set_verification_code
  after_create :update_daemon
  after_update :update_daemon, if: :pages_config_changed?
  after_destroy :update_daemon

  scope :enabled, -> { where('enabled_until >= ?', Time.now ) }
  scope :needs_verification, -> do
    verified_at = arel_table[:verified_at]
    enabled_until = arel_table[:enabled_until]
    threshold = Time.now + VERIFICATION_THRESHOLD

    where(verified_at.eq(nil).or(enabled_until.eq(nil).or(enabled_until.lt(threshold))))
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

  private

  def set_verification_code
    return if self.verification_code.present?

    self.verification_code = SecureRandom.hex(16)
  end

  def update_daemon
    ::Projects::UpdatePagesConfigurationService.new(project).execute
  end

  def pages_config_changed?
    project_id_changed? ||
      domain_changed? ||
      certificate_changed? ||
      key_changed? ||
      became_enabled? ||
      became_disabled?
  end

  def became_enabled?
    enabled_until.present? && !enabled_until_was.present?
  end

  def became_disabled?
    !enabled_until.present? && enabled_until_was.present?
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
    return unless certificate

    @x509 ||= OpenSSL::X509::Certificate.new(certificate)
  rescue OpenSSL::X509::CertificateError
    nil
  end

  def pkey
    return unless key

    @pkey ||= OpenSSL::PKey::RSA.new(key)
  rescue OpenSSL::PKey::PKeyError, OpenSSL::Cipher::CipherError
    nil
  end
end
