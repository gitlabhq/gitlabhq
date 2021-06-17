# frozen_string_literal: true

module Environments
  module CanaryIngress
    class UpdateService < ::BaseService
      def execute_async(environment)
        result = validate(environment)

        return result unless result[:status] == :success

        Environments::CanaryIngress::UpdateWorker.perform_async(environment.id, params)

        success
      end

      # This method actually executes the PATCH request to Kubernetes,
      # that is used by internal processes i.e. sidekiq worker.
      # You should always use `execute_async` to properly validate user's requests.
      def execute(environment)
        canary_ingress = environment.ingresses&.find(&:canary?)

        unless canary_ingress.present?
          return error(_('Canary Ingress does not exist in the environment.'))
        end

        if environment.patch_ingress(canary_ingress, patch_data)
          environment.clear_all_caches
          success
        else
          error(_('Failed to update the Canary Ingress.'), :bad_request)
        end
      end

      private

      def validate(environment)
        unless can?(current_user, :update_environment, environment)
          return error(_('You do not have permission to update the environment.'))
        end

        unless params[:weight].is_a?(Integer) && (0..100).cover?(params[:weight])
          return error(_('Canary weight must be specified and valid range (0..100).'))
        end

        if environment.has_running_deployments?
          return error(_('There are running deployments on the environment. Please retry later.'))
        end

        if ::Gitlab::ApplicationRateLimiter.throttled?(:update_environment_canary_ingress, scope: [environment])
          return error(_("This environment's canary ingress has been updated recently. Please retry later."))
        end

        success
      end

      def patch_data
        {
          metadata: {
            annotations: {
              Gitlab::Kubernetes::Ingress::ANNOTATION_KEY_CANARY_WEIGHT => params[:weight].to_s
            }
          }
        }
      end
    end
  end
end
