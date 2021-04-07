# frozen_string_literal: true

module Clusters
  module Integrations
    class CreateService < BaseContainerService
      InvalidApplicationError = Class.new(StandardError)

      attr_accessor :cluster

      def initialize(container:, cluster:, current_user: nil, params: {})
        @cluster = cluster

        super(container: container, current_user: current_user, params: params)
      end

      def execute
        return ServiceResponse.error(message: 'Unauthorized') unless authorized?

        application_class = Clusters::Cluster::APPLICATIONS[params[:application_type]]
        application = cluster.find_or_build_application(application_class)

        if params[:enabled]
          application.make_externally_installed!
          ServiceResponse.success(message: s_('ClusterIntegration|Integration enabled'), payload: { application: application })
        else
          application.make_externally_uninstalled!
          ServiceResponse.success(message: s_('ClusterIntegration|Integration disabled'), payload: { application: application })
        end
      end

      private

      def authorized?
        Ability.allowed?(current_user, :admin_cluster, cluster)
      end
    end
  end
end
