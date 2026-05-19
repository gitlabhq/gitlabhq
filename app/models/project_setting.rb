# frozen_string_literal: true

class ProjectSetting < ApplicationRecord
  include ::Gitlab::Utils::StrongMemoize
  include EachBatch
  include CascadingProjectSettingAttribute
  include Projects::SquashOption
  include Gitlab::EncryptedAttribute
  include AfterCommitQueue
  include SafelyChangeColumnDefault

  columns_changing_default :auto_duo_code_review_enabled, :duo_remote_flows_enabled, :duo_secret_detection_fp_enabled

  REVIEWER_ASSIGNMENT_STRATEGIES = {
    disabled: 0,
    code_owners: 1
  }.freeze

  ALLOWED_TARGET_PLATFORMS = %w[ios osx tvos watchos android].freeze

  HUMANIZED_ATTRIBUTES = {
    mr_default_title_template: 'Merge request default title template'
  }.freeze

  def self.human_attribute_name(attribute, *options)
    HUMANIZED_ATTRIBUTES[attribute.to_sym] || super
  end

  belongs_to :project, inverse_of: :project_setting

  ignore_column :pages_multiple_versions_enabled, remove_with: '17.9', remove_after: '2025-02-20'
  ignore_column :pages_default_domain_redirect, remove_with: '17.9', remove_after: '2025-02-20'
  ignore_column :code_owner_reviewer_assignment_strategy, remove_with: '19.0', remove_after: '2026-04-22'

  scope :for_projects, ->(projects) { where(project_id: projects) }
  scope :with_namespace, -> { joins(project: :namespace) }

  cascading_attr :web_based_commit_signing_enabled

  attr_encrypted :cube_api_key,
    mode: :per_attribute_iv,
    key: :db_key_base_32,
    algorithm: 'aes-256-gcm',
    encode: false,
    encode_iv: false

  attr_encrypted :product_analytics_configurator_connection_string,
    mode: :per_attribute_iv,
    key: :db_key_base_32,
    algorithm: 'aes-256-gcm',
    encode: false,
    encode_iv: false

  self.primary_key = :project_id

  # TODO: Remove once we confirm schema rollback scenarios no longer require this explicit attribute declaration.
  attribute :reviewer_assignment_strategy, :integer, default: 0, limit: 2

  enum :reviewer_assignment_strategy, REVIEWER_ASSIGNMENT_STRATEGIES,
    prefix: :reviewer_assignment

  validates :merge_commit_template, length: { maximum: Project::MAX_COMMIT_TEMPLATE_LENGTH }
  validates :squash_commit_template, length: { maximum: Project::MAX_COMMIT_TEMPLATE_LENGTH }
  validates :mr_default_title_template, length: { maximum: Project::MAX_MR_TITLE_TEMPLATE_LENGTH }
  validate :mr_default_title_template_no_newlines
  validates :issue_branch_template, length: { maximum: Issue::MAX_BRANCH_TEMPLATE }
  validates :target_platforms, inclusion: { in: ALLOWED_TARGET_PLATFORMS }
  validates :suggested_reviewers_enabled, inclusion: { in: [true, false] }
  validates :merge_request_title_regex_description, length: { maximum:
                                                              Project::MAX_MERGE_REQUEST_TITLE_REGEX_DESCRIPTION }
  validates :merge_request_title_regex, untrusted_regexp: true,
    length: { maximum: Project::MAX_MERGE_REQUEST_TITLE_REGEX }

  validates :pages_unique_domain,
    uniqueness: { if: -> { pages_unique_domain.present? } },
    presence: { if: :require_unique_domain? }

  validate :validates_mr_default_target_self

  validate :pages_unique_domain_availability, if: :pages_unique_domain_changed?

  attribute :legacy_open_source_license_available, default: -> do
    Feature.enabled?(:legacy_open_source_license_available, type: :ops)
  end

  # Checks if a given domain is already assigned to any existing project
  def self.unique_domain_exists?(domain)
    where(pages_unique_domain: domain).exists?
  end

  def target_platforms=(val)
    super(val&.map(&:to_s)&.sort)
  end

  def show_diff_preview_in_email?
    if project.group
      super && project.group&.show_diff_preview_in_email?
    else
      !!super
    end
  end
  strong_memoize_attr :show_diff_preview_in_email?

  def runner_registration_enabled
    Gitlab::CurrentSettings.valid_runner_registrars.include?('project') && read_attribute(:runner_registration_enabled)
  end

  def emails_enabled?
    super && project.namespace.emails_enabled?
  end
  strong_memoize_attr :emails_enabled?

  def pages_primary_domain=(value)
    super(value.presence) # Call the default setter to set the value
  end

  def branch_rule
    ::Projects::AllBranchesRule.new(project)
  end

  def reviewer_auto_assignment_available?
    false
  end

  def reviewer_auto_assignment_enabled?
    reviewer_auto_assignment_available? && reviewer_assignment_strategy != 'disabled'
  end

  private

  def presence_of_merge_request_title_regex_settings
    # Either both are present, or neither
    if merge_request_title_regex.present? != merge_request_title_regex_description.present?
      errors.add :merge_request_title_regex, _('and regex description must be either both set, or neither.')
      errors.add :merge_request_title_regex_description, _('and regex must be either both set, or neither.')
    end
  end

  def mr_default_title_template_no_newlines
    return if mr_default_title_template.blank?

    return unless mr_default_title_template.match?(/[\r\n]/)

    errors.add(:mr_default_title_template, _('must be a single line'))
  end

  def validates_mr_default_target_self
    if mr_default_target_self_changed? && !project.forked?
      errors.add :mr_default_target_self, _('This setting is allowed for forked projects only')
    end
  end

  def enqueue_auto_merge_workers
    run_after_commit do
      AutoMergeProcessWorker.perform_async({ 'project_id' => project.id })
    end
  end

  def require_unique_domain?
    pages_unique_domain_enabled ||
      pages_unique_domain_in_database.present?
  end

  def pages_unique_domain_availability
    host = Gitlab.config.pages&.dig('host')

    return if host.blank?
    return unless Project.where(path: "#{pages_unique_domain}.#{host}").exists?

    errors.add(:pages_unique_domain, s_('ProjectSetting|already in use'))
  end
end

ProjectSetting.prepend_mod
