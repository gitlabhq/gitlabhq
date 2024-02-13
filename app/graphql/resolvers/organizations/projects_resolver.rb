# frozen_string_literal: true

module Resolvers
  module Organizations
    class ProjectsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::ProjectType, null: true

      authorize :read_project

      alias_method :organization, :object

      argument :sort, GraphQL::Types::String,
        required: false,
        description: "Sort order of results. Format: `<field_name>_<sort_direction>`, " \
                     "for example: `id_desc` or `name_asc`",
        alpha: { milestone: '16.9' }

      def resolve(**args)
        project_finder_params = args.merge(organization: organization)

        if %w[path_asc path_desc].include?(project_finder_params[:sort]) &&
            Feature.disabled?(:project_path_sort, current_user, type: :gitlab_com_derisk)
          project_finder_params.delete(:sort)
        end

        ::ProjectsFinder.new(current_user: current_user, params: project_finder_params).execute
      end
    end
  end
end
