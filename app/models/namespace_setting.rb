# frozen_string_literal: true

class NamespaceSetting < ApplicationRecord
  include CascadingNamespaceSettingAttribute
  include Sanitizable
  include ChronicDurationAttribute
  include IgnorableColumns

  ignore_column :third_party_ai_features_enabled, remove_with: '16.11', remove_after: '2024-04-18'
  ignore_column :code_suggestions, remove_with: '17.0', remove_after: '2024-05-16'
  ignore_column :toggle_security_policies_policy_scope, remove_with: '17.0', remove_after: '2024-05-16'

  cascading_attr :toggle_security_policy_custom_ci
  cascading_attr :math_rendering_limits_enabled

  belongs_to :namespace, inverse_of: :namespace_settings

  enum jobs_to_be_done: { basics: 0, move_repository: 1, code_storage: 2, exploring: 3, ci: 4, other: 5 }, _suffix: true
  enum enabled_git_access_protocol: { all: 0, ssh: 1, http: 2 }, _suffix: true

  attribute :default_branch_protection_defaults, default: -> { {} }

  validates :enabled_git_access_protocol, inclusion: { in: enabled_git_access_protocols.keys }
  validates :default_branch_protection_defaults, json_schema: { filename: 'default_branch_protection_defaults' }
  validates :default_branch_protection_defaults, bytesize: { maximum: -> { DEFAULT_BRANCH_PROTECTIONS_DEFAULT_MAX_SIZE } }

  validate :allow_mfa_for_group
  validate :allow_resource_access_token_creation_for_group

  sanitizes! :default_branch_name

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

  def self.allowed_namespace_settings_params
    NAMESPACE_SETTINGS_PARAMS
  end

  def prevent_sharing_groups_outside_hierarchy
    return super if namespace.root?

    namespace.root_ancestor.prevent_sharing_groups_outside_hierarchy
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

  def all_ancestors_have_emails_enabled?
    self.class.where(namespace_id: namespace.self_and_ancestors, emails_enabled: false).none?
  end

  def all_ancestors_allow_diff_preview_in_email?
    !self.class.where(namespace_id: namespace.self_and_ancestors, show_diff_preview_in_email: false).exists?
  end

  def normalize_default_branch_name
    self.default_branch_name = default_branch_name.presence
  end

  def allow_mfa_for_group
    if namespace&.subgroup? && allow_mfa_for_subgroups == false
      errors.add(:allow_mfa_for_subgroups, _('is not allowed since the group is not top-level group.'))
    end
  end

  def allow_resource_access_token_creation_for_group
    if namespace&.subgroup? && !resource_access_token_creation_allowed
      errors.add(:resource_access_token_creation_allowed, _('is not allowed since the group is not top-level group.'))
    end
  end
end

NamespaceSetting.prepend_mod_with('NamespaceSetting')
