# frozen_string_literal: true

module DependencyProxy
  module GroupSettings
    class UpdateService < BaseContainerService
      ALLOWED_ATTRIBUTES = %i[enabled].freeze

      def execute
        return ServiceResponse.error(message: 'Access Denied', http_status: 403) unless allowed?
        return ServiceResponse.error(message: 'Dependency proxy setting not found', http_status: 404) unless dependency_proxy_setting

        if dependency_proxy_setting.update(dependency_proxy_setting_params)
          ServiceResponse.success(payload: { dependency_proxy_setting: dependency_proxy_setting })
        else
          ServiceResponse.error(
            message: dependency_proxy_setting.errors.full_messages.to_sentence || 'Bad request',
            http_status: 400
          )
        end
      end

      private

      def dependency_proxy_setting
        container.dependency_proxy_setting
      end

      def allowed?
        Ability.allowed?(current_user, :admin_dependency_proxy, container)
      end

      def dependency_proxy_setting_params
        params.slice(*ALLOWED_ATTRIBUTES)
      end
    end
  end
end
