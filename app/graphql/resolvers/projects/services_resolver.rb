# frozen_string_literal: true

module Resolvers
  module Projects
    class ServicesResolver < BaseResolver
      prepend ManualAuthorization
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Projects::ServiceType.connection_type, null: true
      authorize :admin_project

      argument :active,
               GraphQL::BOOLEAN_TYPE,
               required: false,
               description: 'Indicates if the service is active.'
      argument :type,
               Types::Projects::ServiceTypeEnum,
               required: false,
               description: 'Class name of the service.'

      alias_method :project, :object

      def resolve(**args)
        authorize!(project)

        services(args[:active], args[:type])
      end

      private

      def services(active, type)
        servs = project.services
        servs = servs.by_active_flag(active) unless active.nil?
        servs = servs.by_type(type) unless type.blank?
        servs
      end
    end
  end
end
