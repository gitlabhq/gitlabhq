# frozen_string_literal: true

class NamespaceSetting < ApplicationRecord
  belongs_to :namespace, inverse_of: :namespace_settings

  validate :default_branch_name_content

  NAMESPACE_SETTINGS_PARAMS = [:default_branch_name].freeze

  self.primary_key = :namespace_id

  def default_branch_name_content
    return if default_branch_name.nil?

    if default_branch_name.blank?
      errors.add(:default_branch_name, "can not be an empty string")
    end
  end
end

NamespaceSetting.prepend_if_ee('EE::NamespaceSetting')
