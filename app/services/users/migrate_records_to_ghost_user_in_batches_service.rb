# frozen_string_literal: true

module Users
  class MigrateRecordsToGhostUserInBatchesService
    LIMIT_SIZE = 100

    def initialize(user_types:)
      @user_types = user_types
      @execution_tracker = Gitlab::Utils::ExecutionTracker.new
    end

    def execute
      ghost_user_migrations.each do |job|
        break if execution_tracker.over_limit?

        service = Users::MigrateRecordsToGhostUserService.new(
          job.user,
          job.initiator_user,
          execution_tracker
        )
        service.execute(hard_delete: job.hard_delete)
      rescue Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError
        defer(job)
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_exception(e)
        reschedule(job)
      end
    end

    private

    attr_reader :execution_tracker

    def ghost_user_migrations
      if Feature.enabled?(:split_ghost_user_migration_queue_into_human_and_non_human, :instance)
        # rubocop:disable CodeReuse/ActiveRecord -- https://docs.gitlab.com/development/database/efficient_in_operator_queries/
        scope = Users::GhostUserMigration.consume_order

        array_scope = Users::GhostUserMigration.unscoped
          .select(:user_type)
          .from(
            Arel::Nodes::Grouping.new(
              Arel::Nodes::ValuesList.new(
                Users::GhostUserMigration.user_types.fetch_values(*@user_types).map { |v| [v] }
              )
            ).as('tbl (user_type)').to_sql
          )

        array_mapping_scope = ->(user_type_expression) do
          Users::GhostUserMigration.where(Users::GhostUserMigration.arel_table[:user_type].eq(user_type_expression))
        end

        finder_query = ->(_consume_after_expression, id_expression) do
          Users::GhostUserMigration.where(Users::GhostUserMigration.arel_table[:id].eq(id_expression))
        end
        # rubocop:enable CodeReuse/ActiveRecord

        Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
          scope: scope,
          array_scope: array_scope,
          array_mapping_scope: array_mapping_scope,
          finder_query: finder_query
        ).execute.limit(LIMIT_SIZE)
      else
        Users::GhostUserMigration.consume_order.limit(LIMIT_SIZE)
      end
    end

    def reschedule(job)
      job.update(consume_after: 30.minutes.from_now)
    end

    def defer(job)
      last_consume_after = Users::GhostUserMigration.maximum(:consume_after) || Time.current
      job.update(consume_after: 30.seconds.after(last_consume_after))
    end
  end
end
