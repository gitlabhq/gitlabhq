# frozen_string_literal: true

module Resolvers
  module AlertManagement
    class HttpIntegrationsResolver < BaseResolver
      include ::Gitlab::Graphql::Laziness

      alias_method :project, :object

      argument :id, Types::GlobalIDType[::AlertManagement::HttpIntegration],
        required: false,
        description: 'ID of the integration.'

      argument :types, [Types::AlertManagement::IntegrationTypeEnum],
        as: :type_identifier,
        default_value: [:http],
        required: false,
        description: 'Types of integrations to return. Default is `[HTTP]`.'

      type Types::AlertManagement::HttpIntegrationType.connection_type, null: true

      def resolve(id: nil, **args)
        return [] unless Ability.allowed?(current_user, :admin_operations, project)

        if id
          integrations_by(gid: id, **args)
        else
          http_integrations(args)
        end
      end

      private

      def integrations_by(gid:, type_identifier: [])
        object = GitlabSchema.find_by_gid(gid)

        defer { object }.then do |integration|
          next [] if integration.nil?
          next [] if project != integration.project
          next [] if type_identifier&.any? && type_identifier.exclude?(integration.type_identifier.to_sym)

          [integration]
        end
      end

      def http_integrations(args)
        ::AlertManagement::HttpIntegrationsFinder.new(project, args).execute
      end
    end
  end
end
