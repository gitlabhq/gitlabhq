# frozen_string_literal: true

class NamespaceSetting < ApplicationRecord
  belongs_to :namespace, inverse_of: :namespace_settings

  validate :default_branch_name_content
  validate :allow_mfa_for_group

  before_validation :normalize_default_branch_name

  NAMESPACE_SETTINGS_PARAMS = [:default_branch_name].freeze

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
end

NamespaceSetting.prepend_if_ee('EE::NamespaceSetting')
