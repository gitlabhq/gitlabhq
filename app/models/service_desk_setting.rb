# frozen_string_literal: true

class ServiceDeskSetting < ApplicationRecord
  include Gitlab::Utils::StrongMemoize

  attribute :custom_email_enabled, default: false
  attr_encrypted :custom_email_smtp_password,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key: Settings.attr_encrypted_db_key_base_32,
    encode: false,
    encode_iv: false

  belongs_to :project
  validates :project_id, presence: true
  validate :valid_issue_template
  validate :valid_project_key
  validates :outgoing_name, length: { maximum: 255 }, allow_blank: true
  validates :project_key,
            length: { maximum: 255 },
            allow_blank: true,
            format: { with: /\A[a-z0-9_]+\z/, message: -> (setting, data) { _("can contain only lowercase letters, digits, and '_'.") } }

  validates :custom_email,
            length: { maximum: 255 },
            uniqueness: true,
            allow_nil: true,
            format: /\A[\w\-._]+@[\w\-.]+\.{1}[a-zA-Z]{2,}\z/
  validates :custom_email_smtp_address, length: { maximum: 255 }
  validates :custom_email_smtp_username, length: { maximum: 255 }

  validates :custom_email,
            presence: true,
            devise_email: true,
            if: :custom_email_enabled?
  validates :custom_email_smtp_address,
            presence: true,
            hostname: { allow_numeric_hostname: true, require_valid_tld: true },
            if: :custom_email_enabled?
  validates :custom_email_smtp_username,
            presence: true,
            if: :custom_email_enabled?
  validates :custom_email_smtp_port,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            if: :custom_email_enabled?

  scope :with_project_key, ->(key) { where(project_key: key) }

  def custom_email_delivery_options
    {
      user_name: custom_email_smtp_username,
      password: custom_email_smtp_password,
      address: custom_email_smtp_address,
      domain: Mail::Address.new(custom_email).domain,
      port: custom_email_smtp_port || 587
    }
  end

  def issue_template_content
    strong_memoize(:issue_template_content) do
      next unless issue_template_key.present?

      TemplateFinder.new(
        :issues, project,
        name: issue_template_key,
        source_template_project: source_template_project
      ).execute.content
    rescue ::Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
    end
  end

  def issue_template_missing?
    issue_template_key.present? && !issue_template_content.present?
  end

  def valid_issue_template
    if issue_template_missing?
      errors.add(:issue_template_key, 'is empty or does not exist')
    end
  end

  def valid_project_key
    if projects_with_same_slug_and_key_exists?
      errors.add(:project_key, 'already in use for another service desk address.')
    end
  end

  private

  def source_template_project
    nil
  end

  def projects_with_same_slug_and_key_exists?
    return false unless project_key

    settings = self.class.with_project_key(project_key).where.not(project_id: project_id).preload(:project)
    project_slug = self.project.full_path_slug

    settings.any? do |setting|
      setting.project.full_path_slug == project_slug
    end
  end
end

ServiceDeskSetting.prepend_mod
