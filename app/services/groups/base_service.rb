# frozen_string_literal: true

module Groups
  class BaseService < ::BaseService
    attr_accessor :group, :current_user, :params

    def initialize(group, user, params = {})
      @group = group
      @current_user = user
      @params = params.dup
    end

    private

    def handle_namespace_settings
      settings_params = params.slice(*::NamespaceSetting.allowed_namespace_settings_params)

      return if settings_params.empty?

      ::NamespaceSetting.allowed_namespace_settings_params.each do |nsp|
        params.delete(nsp)
      end

      ::NamespaceSettings::AssignAttributesService.new(current_user, group, settings_params).execute
    end

    def remove_unallowed_params
      # overridden in EE
    end
  end
end
