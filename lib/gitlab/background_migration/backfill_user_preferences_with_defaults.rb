# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the user_preferences table columns with their default values
    class BackfillUserPreferencesWithDefaults < BatchedMigrationJob
      operation_name :backfill_user_preferences_with_defaults
      feature_category :user_profile

      def perform
        each_sub_batch do |sub_batch|
          connection.transaction do
            sub_batch.where(tab_width: nil).update_all(tab_width: 8)
            sub_batch.where(time_display_relative: nil).update_all(time_display_relative: true)
            sub_batch.where(render_whitespace_in_code: nil).update_all(render_whitespace_in_code: false)
          end
        end
      end
    end
  end
end
