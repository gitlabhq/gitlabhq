# frozen_string_literal: true

module Resolvers
  module Organizations
    class ProjectsResolver < Resolvers::ProjectsResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::ProjectType.connection_type, null: true

      authorize :read_project

      private

      alias_method :organization, :object

      def finder_params(args)
        super.merge(organization: organization)
      end
    end
  end
end
