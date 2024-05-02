# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class IntegrationsResolver < BaseResolver
      include ::Gitlab::Graphql::Laziness

      alias_method :project, :object

      argument :id, ::Types::GlobalIDType,
        required: false,
        description: 'ID of the integration.'

      type Types::AlertManagement::IntegrationType.connection_type, null: true

      def resolve(id: nil)
        if id
          integrations_by(gid: id)
        else
          http_integrations + prometheus_integrations
        end
      end

      private

      def integrations_by(gid:)
        object = GitlabSchema.object_from_id(gid, expected_type: expected_integration_types)
        defer { object }.then do |integration|
          ret = integration if project == integration&.project
          Array.wrap(ret)
        end
      end

      def prometheus_integrations
        return [] unless prometheus_integrations_allowed?

        Array(project.prometheus_integration)
      end

      def http_integrations
        return [] unless http_integrations_allowed?

        ::AlertManagement::HttpIntegrationsFinder.new(project, { type_identifier: :http }).execute
      end

      def prometheus_integrations_allowed?
        Ability.allowed?(current_user, :admin_project, project)
      end

      def http_integrations_allowed?
        Ability.allowed?(current_user, :admin_operations, project)
      end

      def expected_integration_types
        [].tap do |types|
          types << ::AlertManagement::HttpIntegration if http_integrations_allowed?
          types << ::Integrations::Prometheus if prometheus_integrations_allowed?
        end
      end
    end
  end
end
