# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixNonExistingTimelogUsers < BatchedMigrationJob
      GHOST_USER_TYPE = 5

      operation_name :fix_non_existing_timelog_users
      feature_category :team_planning

      def perform
        ghost_id = Users::Internal.ghost.id

        each_sub_batch do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(id), max(id)'))
          query = <<~SQL
            UPDATE timelogs
            SET user_id = #{ghost_id}
            WHERE timelogs.id BETWEEN #{first} AND #{last}
            AND NOT EXISTS (SELECT 1 FROM users WHERE users.id = timelogs.user_id)
          SQL

          sub_batch.connection.execute(query)
        end
      end
    end
  end
end
