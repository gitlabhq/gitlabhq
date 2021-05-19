# frozen_string_literal: true

module Users
  class DeactivateDormantUsersWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    include CronjobQueue

    feature_category :utilization
    tags :exclude_from_kubernetes

    NUMBER_OF_BATCHES = 50
    BATCH_SIZE = 200
    PAUSE_SECONDS = 0.25

    def perform
      return if Gitlab.com?

      return unless ::Gitlab::CurrentSettings.current_application_settings.deactivate_dormant_users

      with_context(caller_id: self.class.name.to_s) do
        NUMBER_OF_BATCHES.times do
          result = User.connection.execute(update_query)

          break if result.cmd_tuples == 0

          sleep(PAUSE_SECONDS)
        end
      end
    end

    private

    def update_query
      <<~SQL
        UPDATE "users"
        SET "state" = 'deactivated'
        WHERE "users"."id" IN (
          (#{users.dormant.to_sql})
          UNION
          (#{users.with_no_activity.to_sql})
          LIMIT #{BATCH_SIZE}
        )
      SQL
    end

    def users
      User.select(:id).limit(BATCH_SIZE)
    end
  end
end
