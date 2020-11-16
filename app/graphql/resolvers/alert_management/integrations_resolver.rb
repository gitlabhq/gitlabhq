# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class IntegrationsResolver < BaseResolver
      alias_method :project, :synchronized_object

      type Types::AlertManagement::IntegrationType.connection_type, null: true

      def resolve(**args)
        http_integrations + prometheus_integrations
      end

      private

      def prometheus_integrations
        return [] unless Ability.allowed?(current_user, :admin_project, project)

        Array(project.prometheus_service)
      end

      def http_integrations
        return [] unless Ability.allowed?(current_user, :admin_operations, project)

        ::AlertManagement::HttpIntegrationsFinder.new(project, {}).execute
      end
    end
  end
end
