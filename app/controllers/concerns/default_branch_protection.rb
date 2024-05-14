# frozen_string_literal: true

module DefaultBranchProtection
  extend ActiveSupport::Concern

  def normalize_default_branch_params!(form_key)
    # The entity being configured will either be the instance or the group
    entity_settings_params = params[form_key]

    if Gitlab::Utils.to_boolean(entity_settings_params[:default_branch_protected]) == false
      entity_settings_params[:default_branch_protection_defaults] =
        ::Gitlab::Access::BranchProtection.protection_none

      return entity_settings_params
    end

    return entity_settings_params unless entity_settings_params.key?(:default_branch_protection_defaults)

    entity_settings_params.delete(:default_branch_protection_level)

    entity_settings_params[:default_branch_protection_defaults][:allowed_to_push].each do |entry|
      entry[:access_level] = entry[:access_level].to_i
    end

    entity_settings_params[:default_branch_protection_defaults][:allowed_to_merge].each do |entry|
      entry[:access_level] = entry[:access_level].to_i
    end

    [:allow_force_push, :code_owner_approval_required, :developer_can_initial_push].each do |key|
      next unless entity_settings_params[:default_branch_protection_defaults].key?(key)

      entity_settings_params[:default_branch_protection_defaults][key] =
        Gitlab::Utils.to_boolean(
          entity_settings_params[:default_branch_protection_defaults][key],
          default: ::Gitlab::Access::BranchProtection.protected_fully[key])
    end
  end
end
