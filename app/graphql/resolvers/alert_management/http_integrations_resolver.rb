# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class HttpIntegrationsResolver < BaseResolver
      include ::Gitlab::Graphql::Laziness

      alias_method :project, :object

      argument :id, Types::GlobalIDType[::AlertManagement::HttpIntegration],
        required: false,
        description: 'ID of the integration.'

      type Types::AlertManagement::HttpIntegrationType.connection_type, null: true

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
        object = GitlabSchema.find_by_gid(gid)

        defer { object }.then do |integration|
          ret = integration if project == integration&.project
          Array.wrap(ret)
        end
      end

      def http_integrations
        ::AlertManagement::HttpIntegrationsFinder.new(project, { type_identifier: :http }).execute
      end
    end
  end
end
