# frozen_string_literal: true

class ProjectSetting < ApplicationRecord
  include ::Gitlab::Utils::StrongMemoize
  include EachBatch

  ALLOWED_TARGET_PLATFORMS = %w(ios osx tvos watchos android).freeze

  belongs_to :project, inverse_of: :project_setting

  scope :for_projects, ->(projects) { where(project_id: projects) }

  attr_encrypted :cube_api_key,
    mode: :per_attribute_iv,
    key: Settings.attr_encrypted_db_key_base_32,
    algorithm: 'aes-256-gcm',
    encode: false,
    encode_iv: false

  attr_encrypted :jitsu_administrator_password,
    mode: :per_attribute_iv,
    key: Settings.attr_encrypted_db_key_base_32,
    algorithm: 'aes-256-gcm',
    encode: false,
    encode_iv: false

  attr_encrypted :product_analytics_clickhouse_connection_string,
    mode: :per_attribute_iv,
    key: Settings.attr_encrypted_db_key_base_32,
    algorithm: 'aes-256-gcm',
    encode: false,
    encode_iv: false

  enum squash_option: {
    never: 0,
    always: 1,
    default_on: 2,
    default_off: 3
  }, _prefix: 'squash'

  self.primary_key = :project_id

  validates :merge_commit_template, length: { maximum: Project::MAX_COMMIT_TEMPLATE_LENGTH }
  validates :squash_commit_template, length: { maximum: Project::MAX_COMMIT_TEMPLATE_LENGTH }
  validates :issue_branch_template, length: { maximum: Issue::MAX_BRANCH_TEMPLATE }
  validates :target_platforms, inclusion: { in: ALLOWED_TARGET_PLATFORMS }
  validates :suggested_reviewers_enabled, inclusion: { in: [true, false] }

  validates :pages_unique_domain,
    uniqueness: { if: -> { pages_unique_domain.present? } },
    presence: { if: :require_unique_domain? }

  validate :validates_mr_default_target_self

  attribute :legacy_open_source_license_available, default: -> do
    Feature.enabled?(:legacy_open_source_license_available, type: :ops)
  end

  def squash_enabled_by_default?
    %w[always default_on].include?(squash_option)
  end

  def squash_readonly?
    %w[always never].include?(squash_option)
  end

  def target_platforms=(val)
    super(val&.map(&:to_s)&.sort)
  end

  def human_squash_option
    case squash_option
    when 'never' then 'Do not allow'
    when 'always' then 'Require'
    when 'default_on' then 'Encourage'
    when 'default_off' then 'Allow'
    end
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

  private

  def validates_mr_default_target_self
    if mr_default_target_self_changed? && !project.forked?
      errors.add :mr_default_target_self, _('This setting is allowed for forked projects only')
    end
  end

  def require_unique_domain?
    pages_unique_domain_enabled ||
      pages_unique_domain_in_database.present?
  end
end

ProjectSetting.prepend_mod
