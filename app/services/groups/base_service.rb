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
      settings_params = params.slice(*::NamespaceSetting::NAMESPACE_SETTINGS_PARAMS)

      return if settings_params.empty?

      ::NamespaceSetting::NAMESPACE_SETTINGS_PARAMS.each do |nsp|
        params.delete(nsp)
      end

      ::NamespaceSettings::UpdateService.new(current_user, group, settings_params).execute
    end

    def remove_unallowed_params
      # overridden in EE
    end
  end
end
