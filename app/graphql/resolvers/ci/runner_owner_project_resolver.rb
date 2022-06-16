# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerOwnerProjectResolver < BaseResolver
      include LooksAhead

      type Types::ProjectType, null: true

      alias_method :runner, :object

      def resolve_with_lookahead(**args)
        resolve_owner
      end

      def preloads
        {
          full_path: [:route]
        }
      end

      def filtered_preloads
        selection = lookahead

        preloads.each.flat_map do |name, requirements|
          selection&.selects?(name) ? requirements : []
        end
      end

      private

      def resolve_owner
        return unless runner.project_type?

        BatchLoader::GraphQL.for(runner.id).batch(key: :runner_owner_projects) do |runner_ids, loader|
          # rubocop: disable CodeReuse/ActiveRecord
          runner_and_projects_with_row_number =
            ::Ci::RunnerProject
              .where(runner_id: runner_ids)
              .select('id, runner_id, project_id, ROW_NUMBER() OVER (PARTITION BY runner_id ORDER BY id ASC)')
          runner_and_owner_projects =
            ::Ci::RunnerProject
              .select(:id, :runner_id, :project_id)
              .from("(#{runner_and_projects_with_row_number.to_sql}) temp WHERE row_number = 1")
          owner_project_id_by_runner_id =
            runner_and_owner_projects
              .group_by(&:runner_id)
              .transform_values { |runner_projects| runner_projects.first.project_id }
          project_ids = owner_project_id_by_runner_id.values.uniq

          all_preloads = unconditional_includes + filtered_preloads
          owner_relation = Project.all
          owner_relation = owner_relation.preload(*all_preloads) if all_preloads.any?
          projects = owner_relation.where(id: project_ids).index_by(&:id)

          runner_ids.each do |runner_id|
            owner_project_id = owner_project_id_by_runner_id[runner_id]
            loader.call(runner_id, projects[owner_project_id])
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
