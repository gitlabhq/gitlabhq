# frozen_string_literal: true

class ProjectCiCdSetting < ApplicationRecord
  include ChronicDurationAttribute
  include EachBatch

  ignore_column :restrict_user_defined_variables, remove_with: '18.3', remove_after: '2025-08-14'

  belongs_to :project, inverse_of: :ci_cd_settings

  DEFAULT_GIT_DEPTH = 20
  NO_ONE_ALLOWED_ROLE = 1
  DEVELOPER_ROLE = 2
  MAINTAINER_ROLE = 3
  OWNER_ROLE = 4

  PIPELINE_VARIABLES_OVERRIDE_ROLES =
    { no_one_allowed: NO_ONE_ALLOWED_ROLE,
      developer: DEVELOPER_ROLE,
      maintainer: MAINTAINER_ROLE,
      owner: OWNER_ROLE }.freeze

  ALLOWED_SUB_CLAIM_COMPONENTS = %w[project_path ref_type ref].freeze

  enum :pipeline_variables_minimum_override_role, PIPELINE_VARIABLES_OVERRIDE_ROLES, prefix: true

  before_validation :set_pipeline_variables_secure_defaults, on: :create
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

  validates :delete_pipelines_in_seconds,
    allow_nil: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: ChronicDuration.parse('1 day'),
      less_than_or_equal_to: ->(_) { ::Gitlab::CurrentSettings.ci_delete_pipelines_in_seconds_limit },
      message: ->(*) {
        format(N_('must be between 1 day and %{limit}'),
          limit: ::Gitlab::CurrentSettings.ci_delete_pipelines_in_seconds_limit_human_readable_long)
      }
    }

  attribute :forward_deployment_enabled, default: true
  attribute :separated_caches, default: true
  validates :merge_trains_skip_train_allowed, inclusion: { in: [true, false] }

  chronic_duration_attr :runner_token_expiration_interval_human_readable, :runner_token_expiration_interval
  chronic_duration_attr_writer :delete_pipelines_in_human_readable, :delete_pipelines_in_seconds

  scope :for_namespace, ->(namespace) { joins(:project).where({ projects: { namespace: namespace } }) }
  scope :for_project, ->(ids) { where(project_id: ids) }
  scope :order_project_id_asc, -> { order(project_id: :asc) }
  scope :configured_to_delete_old_pipelines, -> do
    where.not(delete_pipelines_in_seconds: nil)
  end
  scope :with_pipeline_variables_enabled, -> do
    where.not(pipeline_variables_minimum_override_role: NO_ONE_ALLOWED_ROLE)
  end

  def self.pluck_project_id(limit)
    limit(limit).pluck(:project_id)
  end

  def self.bulk_restrict_pipeline_variables!(project_ids:)
    for_project(project_ids).update_all(pipeline_variables_minimum_override_role: NO_ONE_ALLOWED_ROLE)
  end

  def self.project_ids_not_using_variables(settings_relation, limit)
    project_ids = settings_relation.limit(limit).pluck(:project_id)

    projects_with_vars =
      Ci::PipelineVariable.projects_with_variables(project_ids, limit) +
      Ci::JobVariable.projects_with_variables(project_ids, limit)

    project_ids - projects_with_vars
  end

  def keep_latest_artifacts_available?
    # The project level feature can only be enabled when the feature is enabled instance wide
    Gitlab::CurrentSettings.current_application_settings.keep_latest_artifact? && keep_latest_artifact?
  end

  def override_pipeline_variables_allowed?(role_access_level, user)
    return true unless restrict_user_defined_variables?

    project_minimum_access_level = pipeline_variables_minimum_override_role_for_database

    return false if project_minimum_access_level == NO_ONE_ALLOWED_ROLE

    role_project_minimum_access_level = role_map_pipeline_variables_minimum_override_role[project_minimum_access_level]

    role_access_level >= role_project_minimum_access_level || user&.can_admin_all_resources?
  end

  def restrict_user_defined_variables=(value)
    return unless [true, false].include?(value)

    if value == true && pipeline_variables_minimum_override_role == 'developer'
      self[:pipeline_variables_minimum_override_role] = 'maintainer'
    elsif value == true && pipeline_variables_minimum_override_role != 'developer'
      # keep minimum role as is
    elsif value == false
      self[:pipeline_variables_minimum_override_role] = 'developer'
    end
  end

  def restrict_user_defined_variables?
    self[:pipeline_variables_minimum_override_role] != 'developer'
  end

  private

  def set_pipeline_variables_secure_defaults
    self.pipeline_variables_minimum_override_role = project.root_namespace.pipeline_variables_default_role
  end

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
