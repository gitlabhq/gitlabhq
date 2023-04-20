# frozen_string_literal: true

class ServiceDeskSetting < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include IgnorableColumns

  CUSTOM_EMAIL_VERIFICATION_SUBADDRESS = '+verify'

  ignore_columns %i[
    custom_email_smtp_address
    custom_email_smtp_port
    custom_email_smtp_username
    encrypted_custom_email_smtp_password
    encrypted_custom_email_smtp_password_iv
  ], remove_with: '16.1', remove_after: '2023-05-22'

  attribute :custom_email_enabled, default: false

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

  validates :custom_email_credential,
    presence: true,
    if: :needs_custom_email_credentials?
  validates :custom_email,
    presence: true,
    devise_email: true,
    if: :needs_custom_email_credentials?

  scope :with_project_key, ->(key) { where(project_key: key) }

  def custom_email_credential
    project&.service_desk_custom_email_credential
  end

  def custom_email_verification
    project&.service_desk_custom_email_verification
  end

  def custom_email_address_for_verification
    return unless custom_email.present?

    custom_email.sub("@", "#{CUSTOM_EMAIL_VERIFICATION_SUBADDRESS}@")
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

  def needs_custom_email_credentials?
    custom_email_enabled? || custom_email_verification.present?
  end
end

ServiceDeskSetting.prepend_mod
