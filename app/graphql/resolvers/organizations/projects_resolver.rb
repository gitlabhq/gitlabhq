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
        if %w[path_asc path_desc].include?(args[:sort]) &&
            Feature.disabled?(:project_path_sort, current_user, type: :gitlab_com_derisk)
          args.delete(:sort)
        end

        super.merge(organization: organization)
      end
    end
  end
end
