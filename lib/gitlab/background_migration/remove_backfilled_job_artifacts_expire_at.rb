# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This detects and fixes job artifacts that have `expire_at` wrongly backfilled by the migration
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47723.
    # These job artifacts will not be deleted and will have their `expire_at` removed.
    class RemoveBackfilledJobArtifactsExpireAt < BatchedMigrationJob
      operation_name :update_all
      feature_category :database

      # The migration would have backfilled `expire_at`
      # to midnight on the 22nd of the month of the local timezone,
      # storing it as UTC time in the database.
      #
      # If the timezone setting has changed since the migration,
      # the `expire_at` stored in the database could have changed to a different local time other than midnight.
      # For example:
      # - changing timezone from UTC+02:00 to UTC+02:30 would change the `expire_at` in local time 00:00:00 to 00:30:00.
      # - changing timezone from UTC+00:00 to UTC-01:00 would change the `expire_at` in local time 00:00:00 to 23:00:00
      #   on the previous day (21st).
      #
      # Therefore job artifacts that have `expire_at` exactly on the 00, 30 or 45 minute mark
      # on the dates 21, 22, 23 of the month will not be deleted.
      # https://en.wikipedia.org/wiki/List_of_UTC_time_offsets
      EXPIRES_ON_21_22_23_AT_MIDNIGHT_IN_TIMEZONE = <<~SQL
        EXTRACT(day FROM timezone('UTC', expire_at)) IN (21, 22, 23)
        AND EXTRACT(minute FROM timezone('UTC', expire_at)) IN (0, 30, 45)
        AND EXTRACT(second FROM timezone('UTC', expire_at)) = 0
      SQL

      scope_to ->(relation) {
        relation.where(EXPIRES_ON_21_22_23_AT_MIDNIGHT_IN_TIMEZONE)
          .or(relation.where(file_type: 3))
      }

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(expire_at: nil)
        end
      end
    end
  end
end
