# frozen_string_literal: true

class NamespaceSetting < ApplicationRecord
  include CascadingNamespaceSettingAttribute
  include Sanitizable
  include ChronicDurationAttribute
  include EachBatch

  ignore_column :token_expiry_notify_inherited, remove_with: '17.9', remove_after: '2025-01-11'
  enum pipeline_variables_default_role: ProjectCiCdSetting::PIPELINE_VARIABLES_OVERRIDE_ROLES, _prefix: true

  ignore_column :third_party_ai_features_enabled, remove_with: '16.11', remove_after: '2024-04-18'
  ignore_column :code_suggestions, remove_with: '17.8', remove_after: '2024-05-16'

  cascading_attr :math_rendering_limits_enabled, :resource_access_token_notify_inherited

  scope :for_namespaces, ->(namespaces) { where(namespace: namespaces) }

  belongs_to :namespace, inverse_of: :namespace_settings

  enum jobs_to_be_done: { basics: 0, move_repository: 1, code_storage: 2, exploring: 3, ci: 4, other: 5 }, _suffix: true
  enum enabled_git_access_protocol: { all: 0, ssh: 1, http: 2 }, _suffix: true
  enum seat_control: { off: 0, user_cap: 1, block_overages: 2 }, _prefix: true

  attribute :default_branch_protection_defaults, default: -> { {} }

  validates :enabled_git_access_protocol, inclusion: { in: enabled_git_access_protocols.keys }
  validates :default_branch_protection_defaults, json_schema: { filename: 'default_branch_protection_defaults' }
  validates :default_branch_protection_defaults, bytesize: { maximum: -> { DEFAULT_BRANCH_PROTECTIONS_DEFAULT_MAX_SIZE } }

  sanitizes! :default_branch_name

  before_validation :set_pipeline_variables_default_role, on: :create

  before_validation :normalize_default_branch_name

  chronic_duration_attr :runner_token_expiration_interval_human_readable, :runner_token_expiration_interval
  chronic_duration_attr :subgroup_runner_token_expiration_interval_human_readable, :subgroup_runner_token_expiration_interval
  chronic_duration_attr :project_runner_token_expiration_interval_human_readable, :project_runner_token_expiration_interval

  NAMESPACE_SETTINGS_PARAMS = %i[
    emails_enabled
    default_branch_name
    resource_access_token_creation_allowed
    prevent_sharing_groups_outside_hierarchy
    new_user_signups_cap
    setup_for_company
    seat_control
    jobs_to_be_done
    runner_token_expiration_interval
    enabled_git_access_protocol
    subgroup_runner_token_expiration_interval
    project_runner_token_expiration_interval
    default_branch_protection_defaults
    math_rendering_limits_enabled
    lock_math_rendering_limits_enabled
  ].freeze

  # matches the size set in the database constraint
  DEFAULT_BRANCH_PROTECTIONS_DEFAULT_MAX_SIZE = 1.kilobyte

  self.primary_key = :namespace_id

  def self.declarative_policy_class
    "Ci::NamespaceSettingPolicy"
  end

  def self.allowed_namespace_settings_params
    NAMESPACE_SETTINGS_PARAMS
  end

  def prevent_sharing_groups_outside_hierarchy
    return super if namespace.root?

    namespace.root_ancestor.prevent_sharing_groups_outside_hierarchy
  end

  def pipeline_variables_default_role
    # We consider only the root namespace setting to cascade the default value to all projects.
    # By ignoring settings from sub-groups we don't need to deal with complexities from
    # hierarchical settings.
    return namespace.root_ancestor.pipeline_variables_default_role unless namespace.root?

    super
  end

  def emails_enabled?
    return emails_enabled unless namespace.has_parent?

    all_ancestors_have_emails_enabled?
  end

  # Where this function is used, a returned "nil" is considered a truthy value
  def show_diff_preview_in_email?
    return show_diff_preview_in_email unless namespace.has_parent?

    all_ancestors_allow_diff_preview_in_email?
  end

  def runner_registration_enabled?
    runner_registration_enabled && all_ancestors_have_runner_registration_enabled?
  end

  def all_ancestors_have_runner_registration_enabled?
    return false unless Gitlab::CurrentSettings.valid_runner_registrars.include?('group')

    return true unless namespace.has_parent?

    !self.class.where(namespace_id: namespace.ancestors, runner_registration_enabled: false).exists?
  end

  def allow_runner_registration_token?
    settings = Gitlab::CurrentSettings.current_application_settings

    settings.allow_runner_registration_token && namespace.root_ancestor.allow_runner_registration_token
  end

  private

  def set_pipeline_variables_default_role
    # After FF  `change_namespace_default_role_for_pipeline_variables` rollout - we have to remove both FF and pipeline_variables_default_role = NO_ONE_ALLOWED_ROLE
    # As any self-managed and Dedicated instance should opt-in by changing their namespace settings explicitly.
    # NO_ONE_ALLOWED will be set as the default value for namespace_settings through a database migration.

    # WARNING: Removing this FF could cause breaking changes for self-hosted and dedicated instances.

    return if Feature.disabled?(:change_namespace_default_role_for_pipeline_variables, namespace)

    self.pipeline_variables_default_role = ProjectCiCdSetting::NO_ONE_ALLOWED_ROLE
  end

  def all_ancestors_have_emails_enabled?
    self.class.where(namespace_id: namespace.self_and_ancestors, emails_enabled: false).none?
  end

  def all_ancestors_allow_diff_preview_in_email?
    !self.class.where(namespace_id: namespace.self_and_ancestors, show_diff_preview_in_email: false).exists?
  end

  def normalize_default_branch_name
    self.default_branch_name = default_branch_name.presence
  end

  def subgroup?
    !!namespace&.subgroup?
  end
end

NamespaceSetting.prepend_mod_with('NamespaceSetting')
