# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration populates the new `users.color_mode_id` column
    class BackfillUsersColorModeId < BatchedMigrationJob
      DARK_THEME_ID = 11
      DARK_COLOR_MODE_ID = 2

      operation_name :update_all
      scope_to ->(relation) { relation.where(theme_id: DARK_THEME_ID) }

      feature_category :user_profile

      def perform
        each_sub_batch do |sub_batch|
          ApplicationRecord.connection.execute <<~SQL
            UPDATE users
            SET color_mode_id = #{DARK_COLOR_MODE_ID}
            WHERE users.id IN (#{sub_batch.select(:id).to_sql})
          SQL
        end
      end
    end
  end
end
