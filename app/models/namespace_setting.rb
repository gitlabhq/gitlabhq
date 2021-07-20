# frozen_string_literal: true

class NamespaceSetting < ApplicationRecord
  include CascadingNamespaceSettingAttribute

  cascading_attr :delayed_project_removal

  belongs_to :namespace, inverse_of: :namespace_settings

  validate :default_branch_name_content
  validate :allow_mfa_for_group
  validate :allow_resource_access_token_creation_for_group

  before_validation :normalize_default_branch_name

  NAMESPACE_SETTINGS_PARAMS = [:default_branch_name, :delayed_project_removal,
                               :lock_delayed_project_removal, :resource_access_token_creation_allowed,
                               :prevent_sharing_groups_outside_hierarchy, :new_user_signups_cap].freeze

  self.primary_key = :namespace_id

  private

  def normalize_default_branch_name
    self.default_branch_name = nil if default_branch_name.blank?
  end

  def default_branch_name_content
    return if default_branch_name.nil?

    if default_branch_name.blank?
      errors.add(:default_branch_name, "can not be an empty string")
    end
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
