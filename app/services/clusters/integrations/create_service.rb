# frozen_string_literal: true

module Clusters
  module Integrations
    class CreateService < BaseContainerService
      attr_accessor :cluster

      def initialize(container:, cluster:, current_user: nil, params: {})
        @cluster = cluster

        super(container: container, current_user: current_user, params: params)
      end

      def execute
        return ServiceResponse.error(message: 'Unauthorized') unless authorized?

        integration.enabled = params[:enabled]
        integration.save!

        if integration.enabled?
          ServiceResponse.success(message: s_('ClusterIntegration|Integration enabled'), payload: { integration: integration })
        else
          ServiceResponse.success(message: s_('ClusterIntegration|Integration disabled'), payload: { integration: integration })
        end
      end

      private

      def integration
        @integration ||= \
          case params[:application_type]
          when 'prometheus'
            cluster.find_or_build_integration_prometheus
          when 'elastic_stack'
            cluster.find_or_build_integration_elastic_stack
          else
            raise ArgumentError, "invalid application_type: #{params[:application_type]}"
          end
      end

      def authorized?
        Ability.allowed?(current_user, :admin_cluster, cluster)
      end
    end
  end
end
