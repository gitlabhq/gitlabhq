# frozen_string_literal: true

module DependencyProxy
  module ImageTtlGroupPolicies
    class UpdateService < BaseContainerService
      include Gitlab::Utils::StrongMemoize

      ALLOWED_ATTRIBUTES = %i[enabled ttl].freeze

      def execute
        return ServiceResponse.error(message: 'Access Denied', http_status: 403) unless allowed?
        return ServiceResponse.error(message: 'Dependency proxy image TTL Policy not found', http_status: 404) unless dependency_proxy_image_ttl_policy

        if dependency_proxy_image_ttl_policy.update(dependency_proxy_image_ttl_policy_params)
          ServiceResponse.success(payload: { dependency_proxy_image_ttl_policy: dependency_proxy_image_ttl_policy })
        else
          ServiceResponse.error(
            message: dependency_proxy_image_ttl_policy.errors.full_messages.to_sentence || 'Bad request',
            http_status: 400
          )
        end
      end

      private

      def dependency_proxy_image_ttl_policy
        strong_memoize(:dependency_proxy_image_ttl_policy) do
          container.dependency_proxy_image_ttl_policy
        end
      end

      def allowed?
        Ability.allowed?(current_user, :admin_dependency_proxy, container)
      end

      def dependency_proxy_image_ttl_policy_params
        params.slice(*ALLOWED_ATTRIBUTES)
      end
    end
  end
end
