class SamlProvider < ActiveRecord::Base
  belongs_to :group

  validates :group, presence: true, top_level_group: true
  validates :sso_url, presence: true, url: { protocols: %w(https) }
  validates :certificate_fingerprint, presence: true, certificate_fingerprint: true

  after_initialize :set_defaults, if: :new_record?

  NAME_IDENTIFIER_FORMAT = 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'.freeze

  def assertion_consumer_service_url
    "#{full_group_path}/-/saml/callback"
  end

  def issuer
    full_group_path
  end

  def name_identifier_format
    NAME_IDENTIFIER_FORMAT
  end

  def certificate_fingerprint=(value)
    super(strip_left_to_right_chars(value))
  end

  def settings
    {
      assertion_consumer_service_url: assertion_consumer_service_url,
      issuer: issuer,
      idp_cert_fingerprint: certificate_fingerprint,
      idp_sso_target_url: sso_url,
      name_identifier_format: name_identifier_format
    }
  end

  private

  def full_group_path
    "#{host}/groups/#{group.full_path}"
  end

  def set_defaults
    self.enabled = true
  end

  def host
    @host ||= Gitlab.config.gitlab.url
  end

  def strip_left_to_right_chars(input)
    input&.gsub(/[\u200E]/, '')
  end
end
