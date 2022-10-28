# frozen_string_literal: true

module ProtectedRefs
  class AccessLevelParams
    attr_reader :type, :params

    def initialize(type, params, with_defaults: true)
      @type = type
      @params = with_defaults ? params_with_default(params) : params
    end

    def access_levels
      ce_style_access_level
    end

    private

    def params_with_default(params)
      params[:"#{type}_access_level"] ||= Gitlab::Access::MAINTAINER if use_default_access_level?(params)
      params
    end

    def use_default_access_level?(params)
      true
    end

    def ce_style_access_level
      access_level = params[:"#{type}_access_level"]

      return [] unless access_level

      [{ access_level: access_level }]
    end
  end
end

ProtectedRefs::AccessLevelParams.prepend_mod_with('ProtectedRefs::AccessLevelParams')
