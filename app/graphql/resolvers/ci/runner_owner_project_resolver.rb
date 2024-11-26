# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerOwnerProjectResolver < BaseResolver
      include LooksAhead

      type Types::ProjectType, null: true

      alias_method :runner, :object

      def resolve_with_lookahead(**_args)
        resolve_owner
      end

      private

      def node_selection(selection = lookahead)
        # There are no nodes or edges selections in RunnerOwnerProjectResolver, but rather a project directly
        selection
      end

      def unconditional_includes
        [:project_feature]
      end

      def preloads
        {
          full_path: [:route, { namespace: [:route] }],
          web_url: [:route, { namespace: [:route] }]
        }
      end

      def resolve_owner
        return unless runner.project_type?

        BatchLoader::GraphQL.for(runner.id).batch do |runner_ids, loader|
          # rubocop: disable CodeReuse/ActiveRecord -- this runs on a limited number of records
          runner_id_to_owner_id =
            ::Ci::Runner.project_type.id_in(runner_ids)
              .pluck(:id, :sharding_key_id)
              .to_h
          # rubocop: enable CodeReuse/ActiveRecord

          projects = apply_lookahead(Project.id_in(runner_id_to_owner_id.values.uniq))
          Preloaders::ProjectPolicyPreloader.new(projects, current_user).execute
          projects_by_id = projects.index_by(&:id)

          runner_ids.each do |runner_id|
            owner_project_id = runner_id_to_owner_id[runner_id]
            loader.call(runner_id, projects_by_id[owner_project_id])
          end
        end
      end
    end
  end
end
