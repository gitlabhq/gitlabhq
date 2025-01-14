# frozen_string_literal: true

module Ci
  module Runners
    # Service used to recompute runner owners after a project is deleted.
    class UpdateProjectRunnersOwnerService
      BATCH_SIZE = 1000

      # @param [Int] project_id: the ID of the deleted project
      def initialize(project_id)
        @project_id = project_id
      end

      def execute
        # Since the project was deleted in the 'main' database, let's ensure that the respective
        # ci_runner_projects join records are also gone (would be handled by LFK otherwise,
        # but it is a helpful precondition for the service's logic)
        Ci::RunnerProject.belonging_to_project(project_id).each_batch do |batch|
          batch.delete_all
        end

        # rubocop: disable CodeReuse/ActiveRecord -- this query is too specific to generalize on the models
        runner_projects =
          Ci::RunnerProject.where(Ci::RunnerProject.arel_table[:runner_id].eq(Ci::Runner.arel_table[:id]))
        orphaned_runners = Ci::Runner.project_type.with_sharding_key(project_id)

        orphaned_runners.select(:id).each_batch(of: BATCH_SIZE) do |batch|
          runners_missing_owner_project = Ci::Runner.id_in(batch.limit(BATCH_SIZE).pluck_primary_key)
          runners_with_fallback_owner = runners_missing_owner_project.where_exists(runner_projects.limit(1))

          Ci::Runner.transaction do
            runner_ids = runners_with_fallback_owner.limit(BATCH_SIZE).pluck_primary_key

            runners_with_fallback_owner.update_all(runner_id_update_query(Ci::Runner.arel_table[:id]))
            Ci::RunnerManager.project_type.for_runner(runner_ids)
              .update_all(runner_id_update_query(Ci::RunnerManager.arel_table[:runner_id]))
            Ci::RunnerTagging.project_type.for_runner(runner_ids)
              .update_all(runner_id_update_query(Ci::RunnerTagging.arel_table[:runner_id]))

            # Delete any orphaned runners that are still pointing to the project
            #   (they are the ones which no longer have any matching ci_runner_projects records)
            # We can afford to sidestep Ci::Runner hooks since we know by definition that
            # there are no Ci::RunnerProject models pointing to these runners (it's the reason they are being deleted)
            runners_missing_owner_project.project_type.with_sharding_key(project_id).delete_all
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        ServiceResponse.success
      end

      private

      attr_reader :project_id

      def runner_id_update_query(runner_id_column)
        # rubocop: disable CodeReuse/ActiveRecord -- this query is too specific to generalize on the models
        runner_projects = Ci::RunnerProject.where(Ci::RunnerProject.arel_table[:runner_id].eq(runner_id_column))

        <<~SQL
          sharding_key_id = (#{runner_projects.order(id: :asc).limit(1).select(:project_id).to_sql})
        SQL
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
