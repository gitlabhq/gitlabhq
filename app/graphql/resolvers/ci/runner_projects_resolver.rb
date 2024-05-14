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

      def resolve_with_lookahead(**args)
        return unless runner.project_type?

        # rubocop:disable CodeReuse/ActiveRecord
        BatchLoader::GraphQL.for(runner.id).batch do |runner_ids, loader|
          plucked_runner_and_project_ids = ::Ci::RunnerProject
                                             .select(:runner_id, :project_id)
                                             .where(runner_id: runner_ids)
                                             .pluck(:runner_id, :project_id)

          unique_project_ids = plucked_runner_and_project_ids.collect { |_runner_id, project_id| project_id }.uniq
          projects = ProjectsFinder
                       .new(current_user: current_user,
                         params: project_finder_params(args),
                         project_ids_relation: unique_project_ids)
                       .execute
          projects = apply_lookahead(projects)
          Preloaders::ProjectPolicyPreloader.new(projects, current_user).execute
          sorted_project_ids = projects.map(&:id)
          projects_by_id = projects.index_by(&:id)

          # In plucked_runner_and_project_ids, first() represents the runner ID, and second() the project ID,
          # so let's group the project IDs by runner ID
          project_ids_by_runner_id =
            plucked_runner_and_project_ids
              .group_by(&:first)
              .transform_values { |runner_id_and_project_id| runner_id_and_project_id.map(&:second) }
          # Reorder the project IDs according to the order in sorted_project_ids
          sorted_project_ids_by_runner_id =
            project_ids_by_runner_id.transform_values { |project_ids| sorted_project_ids.intersection(project_ids) }

          runner_ids.each do |runner_id|
            runner_project_ids = sorted_project_ids_by_runner_id[runner_id] || []
            runner_projects = runner_project_ids.map { |id| projects_by_id[id] }

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
