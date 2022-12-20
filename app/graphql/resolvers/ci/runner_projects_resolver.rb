# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerProjectsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead
      include ProjectSearchArguments

      type Types::ProjectType.connection_type, null: true
      authorize :read_runner
      authorizes_object!

      alias_method :runner, :object

      argument :sort, GraphQL::Types::String,
               required: false,
               default_value: 'id_asc', # TODO: Remove in %16.0 and move :sort to ProjectSearchArguments, see https://gitlab.com/gitlab-org/gitlab/-/issues/372117
               deprecated: {
                 reason: 'Default sort order will change in 16.0. ' \
                   'Specify `"id_asc"` if query results\' order is important',
                 milestone: '15.4'
               },
               description: "Sort order of results. Format: `<field_name>_<sort_direction>`, " \
                 "for example: `id_desc` or `name_asc`"

      def resolve_with_lookahead(**args)
        return unless runner.project_type?

        # rubocop:disable CodeReuse/ActiveRecord
        BatchLoader::GraphQL.for(runner.id).batch(key: :runner_projects) do |runner_ids, loader|
          plucked_runner_and_project_ids = ::Ci::RunnerProject
                                             .select(:runner_id, :project_id)
                                             .where(runner_id: runner_ids)
                                             .pluck(:runner_id, :project_id)

          project_ids = plucked_runner_and_project_ids.collect { |_runner_id, project_id| project_id }.uniq
          projects = ProjectsFinder
                       .new(current_user: current_user,
                            params: project_finder_params(args),
                            project_ids_relation: project_ids)
                       .execute
          projects = apply_lookahead(projects)
          Preloaders::ProjectPolicyPreloader.new(projects, current_user).execute
          projects_by_id = projects.index_by(&:id)

          # In plucked_runner_and_project_ids, first() represents the runner ID, and second() the project ID,
          # so let's group the project IDs by runner ID
          runner_project_ids_by_runner_id =
            plucked_runner_and_project_ids
              .group_by(&:first)
              .transform_values { |values| values.map(&:second).filter_map { |project_id| projects_by_id[project_id] } }

          runner_ids.each do |runner_id|
            runner_projects = runner_project_ids_by_runner_id[runner_id] || []

            loader.call(runner_id, runner_projects)
          end
        end
        # rubocop:enable CodeReuse/ActiveRecord
      end

      private

      def unconditional_includes
        [:project_feature]
      end

      def preloads
        super.merge({
                      full_path: [:route, { namespace: [:route] }],
                      web_url: [:route, { namespace: [:route] }]
                    })
      end
    end
  end
end
