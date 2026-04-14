# frozen_string_literal: true

module ProtectedRefs
  class AccessLevelParams
    attr_reader :type, :params

    def initialize(type, params, with_defaults: true)
      @type = type
      @params = with_defaults ? params_with_default(params) : params
    end

    def access_levels
      role_based_access_level + deploy_key_access_levels
    end

    private

    def params_with_default(params)
      params[:"#{type}_access_level"] ||= Gitlab::Access::MAINTAINER if use_default_access_level?(params)
      params
    end

    def use_default_access_level?(params)
      allowed_to_params = params[:"allowed_to_#{type}"]
      return true if allowed_to_params.blank?

      deploy_key_entries(allowed_to_params).blank?
    end

    def role_based_access_level
      access_level = params[:"#{type}_access_level"]

      return [] unless access_level

      [{ access_level: access_level }]
    end

    def deploy_key_access_levels
      allowed_to_params = params[:"allowed_to_#{type}"]
      return [] if allowed_to_params.blank?

      deploy_key_entries(allowed_to_params)
    end

    def deploy_key_entries(allowed_to_params)
      allowed_to_params.select { |entry| entry[:deploy_key_id].present? }
    end
  end
end

ProtectedRefs::AccessLevelParams.prepend_mod_with('ProtectedRefs::AccessLevelParams')
