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
        return [] unless Ability.allowed?(current_user, :admin_operations, project)

        if id
          integrations_by(gid: id)
        else
          http_integrations
        end
      end

      private

      def integrations_by(gid:)
        object = GitlabSchema.object_from_id(gid, expected_type: [
          ::AlertManagement::HttpIntegration,
          ::Integrations::Prometheus
        ])

        defer { object }.then do |integration|
          next [] unless integration&.project == project

          if integration.is_a?(::Integrations::Prometheus)
            project.alert_management_http_integrations
              .for_endpoint_identifier('legacy-prometheus').to_a
          else
            [integration]
          end
        end
      end

      def http_integrations
        ::AlertManagement::HttpIntegrationsFinder.new(project).execute
      end
    end
  end
end
