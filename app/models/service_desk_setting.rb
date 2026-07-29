# frozen_string_literal: true

class ServiceDeskSetting < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include Cells::Claimable

  CUSTOM_EMAIL_VERIFICATION_SUBADDRESS = '+verify'

  attribute :custom_email_enabled, default: false

  cells_claims_scope do
    where.not(custom_email: nil).or(where.not(project_key_address_slug: nil))
  end

  cells_claims_attribute :custom_email,
    type: CLAIMS_BUCKET_TYPE::SERVICE_DESK_CUSTOM_EMAILS,
    if: ->(record) { record.custom_email.present? }
  cells_claims_attribute :project_key_address_slug,
    type: CLAIMS_BUCKET_TYPE::SERVICE_DESK_PROJECT_KEY_ADDRESS_SLUGS,
    feature_flag: :cells_claims_service_desk_settings_project_key_address_slugs,
    if: ->(record) { record.project_key_address_slug.present? }
  cells_claims_metadata subject_type: CLAIMS_SUBJECT_TYPE::PROJECT, subject_key: :project_id

  belongs_to :project

  before_save :set_project_key_address_slug

  validates :project_id, presence: true
  validate :valid_issue_template
  validate :valid_project_key
  validate :custom_email_enabled_state
  validates :outgoing_name, length: { maximum: 255 }, allow_blank: true
  validates :project_key,
    length: { maximum: 255 },
    allow_blank: true,
    format: { with: /\A[a-z0-9_]+\z/, message: ->(setting, data) { _("can contain only lowercase letters, digits, and '_'.") } }

  # Don't use Devise.email_regexp or URI::MailTo::EMAIL_REGEXP to be a bit more restrictive
  # on the format of an email. For example because we don't want to allow `+` and other
  # subaddress delimeters in the local part.
  validates :custom_email,
    length: { maximum: 255 },
    uniqueness: true,
    allow_nil: true,
    format: Gitlab::Email::ServiceDesk::CustomEmail::EMAIL_REGEXP_WITH_ANCHORS

  validates :custom_email_credential,
    presence: true,
    if: :needs_custom_email_credentials?
  validates :custom_email,
    presence: true,
    devise_email: true,
    if: :needs_custom_email_credentials?

  scope :with_project_key, ->(key) { where(project_key: key) }
  scope :with_any_project_key, -> { where.not(project_key: nil) }
  scope :preload_project, -> { preload(:project) }
  scope :for_projects_inside_route_path, ->(path) do
    where(
      project_id: Route.for_routable_type('Project').inside_path(path).select(:source_id)
    )
  end

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

  # Whether the current project_key would collide with another project's service
  # desk address for the project's current full path slug. Used to block a
  # project rename or transfer that would create such a collision.
  def project_key_address_slug_conflict?
    project_key.present? && projects_with_same_slug_and_key_exists?
  end

  def refresh_project_key_address_slug!
    return unless project_key.present?

    save!
  end

  def custom_email_enabled_state
    return unless custom_email_enabled?

    if custom_email_verification.blank? || !custom_email_verification.finished?
      errors.add(:custom_email_enabled, 'cannot be enabled until verification process has finished.')
    end
  end

  def tickets_confidential_by_default?
    # Tickets in public projects should always be confidential by default
    return true if project.public?

    self[:tickets_confidential_by_default]
  end

  private

  def set_project_key_address_slug
    self.project_key_address_slug =
      project_key.present? ? "#{project.full_path_slug}-#{project_key}" : nil
  end

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
