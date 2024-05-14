# frozen_string_literal: true

module Resolvers
  module Projects
    # TODO: Remove in 17.0, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108418
    class ServicesResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Projects::ServiceType.connection_type, null: true
      authorize :admin_project
      authorizes_object!

      argument :active,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Indicates if the integration is active.'
      argument :type,
        Types::Projects::ServiceTypeEnum,
        required: false,
        description: 'Type of integration.'

      alias_method :project, :object

      def resolve(active: nil, type: nil)
        items = project.integrations
        items = items.by_active_flag(active) unless active.nil?
        items = items.by_type(type) unless type.blank?
        items
      end
    end
  end
end
