# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class HttpIntegrationsResolver < BaseResolver
      alias_method :project, :object

      type Types::AlertManagement::HttpIntegrationType.connection_type, null: true

      def resolve(**args)
        http_integrations
      end

      private

      def http_integrations
        return [] unless Ability.allowed?(current_user, :admin_operations, project)

        ::AlertManagement::HttpIntegrationsFinder.new(project, {}).execute
      end
    end
  end
end
