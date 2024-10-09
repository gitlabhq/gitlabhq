# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixPickUpAtCiDeletedObject < BatchedMigrationJob
      operation_name :fix_pick_up_at_ci_deleted_objects
      feature_category :job_artifacts

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('pick_up_at > ?', 15.minutes.from_now)
            .update_all("pick_up_at = least(pick_up_at, now() + '1 hour'::interval)")
        end
      end
    end
  end
end
