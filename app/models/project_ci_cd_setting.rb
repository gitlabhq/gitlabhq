# frozen_string_literal: true

class ProjectCiCdSetting < ApplicationRecord
  include ChronicDurationAttribute

  belongs_to :project, inverse_of: :ci_cd_settings

  DEFAULT_GIT_DEPTH = 20
  NO_ONE_ALLOWED_ROLE = 1
  DEVELOPER_ROLE = 2
  MAINTAINER_ROLE = 3
  OWNER_ROLE = 4

  ALLOWED_SUB_CLAIM_COMPONENTS = %w[project_path ref_type ref].freeze

  enum pipeline_variables_minimum_override_role: {
    no_one_allowed: NO_ONE_ALLOWED_ROLE,
    developer: DEVELOPER_ROLE,
    maintainer: MAINTAINER_ROLE,
    owner: OWNER_ROLE
  }, _prefix: true

  before_create :set_default_git_depth

  validates :id_token_sub_claim_components, length: {
    minimum: 1
  }, allow_nil: false
  validate :validate_sub_claim_components
  validates :default_git_depth,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1000
    },
    allow_nil: true

  attribute :forward_deployment_enabled, default: true
  attribute :separated_caches, default: true
  validates :merge_trains_skip_train_allowed, inclusion: { in: [true, false] }

  chronic_duration_attr :runner_token_expiration_interval_human_readable, :runner_token_expiration_interval

  def keep_latest_artifacts_available?
    # The project level feature can only be enabled when the feature is enabled instance wide
    Gitlab::CurrentSettings.current_application_settings.keep_latest_artifact? && keep_latest_artifact?
  end

  def override_pipeline_variables_allowed?(role_access_level)
    return true unless restrict_user_defined_variables?

    project_minimum_access_level = pipeline_variables_minimum_override_role_for_database

    return false if project_minimum_access_level == NO_ONE_ALLOWED_ROLE

    role_project_minimum_access_level = role_map_pipeline_variables_minimum_override_role[project_minimum_access_level]

    role_access_level >= role_project_minimum_access_level
  end

  private

  def role_map_pipeline_variables_minimum_override_role
    {
      DEVELOPER_ROLE => Gitlab::Access::DEVELOPER,
      MAINTAINER_ROLE => Gitlab::Access::MAINTAINER,
      OWNER_ROLE => Gitlab::Access::OWNER
    }
  end

  def set_default_git_depth
    self.default_git_depth ||= DEFAULT_GIT_DEPTH
  end

  def validate_sub_claim_components
    if id_token_sub_claim_components[0] != 'project_path'
      errors.add(:id_token_sub_claim_components, _('project_path must be the first element of the sub claim'))
    end

    id_token_sub_claim_components.each do |component|
      unless ALLOWED_SUB_CLAIM_COMPONENTS.include?(component)
        errors.add(:id_token_sub_claim_components,
          format(_("%{component} is not an allowed sub claim component"), component: component))
      end
    end
  end
end

ProjectCiCdSetting.prepend_mod_with('ProjectCiCdSetting')
