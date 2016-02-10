class PagesDomain < ActiveRecord::Base
  belongs_to :project

  validates :domain, hostname: true
  validates_uniqueness_of :domain, allow_nil: true, allow_blank: true
  validates :certificate, certificate: true, allow_nil: true, allow_blank: true
  validates :key, certificate_key: true, allow_nil: true, allow_blank: true

  attr_encrypted :pages_custom_certificate_key, mode: :per_attribute_iv_and_salt, key: Gitlab::Application.secrets.db_key_base

  after_create :update
  after_save :update
  after_destroy :update

  def url
    return unless domain
    return unless Dir.exist?(project.public_pages_path)

    if certificate
      return "https://#{domain}"
    else
      return "http://#{domain}"
    end
  end

  def update
    UpdatePagesConfigurationService.new(project).execute
  end
end
