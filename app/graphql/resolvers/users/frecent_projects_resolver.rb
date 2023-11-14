# frozen_string_literal: true

module Resolvers
  module Users
    class FrecentProjectsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type [Types::ProjectType], null: true

      def resolve
        return unless current_user.present?

        if Feature.disabled?(:frecent_namespaces_suggestions, current_user)
          raise_resource_not_available_error!("'frecent_namespaces_suggestions' feature flag is disabled")
        end

        ::Users::ProjectVisit.frecent_projects(user_id: current_user.id)
      end
    end
  end
end
