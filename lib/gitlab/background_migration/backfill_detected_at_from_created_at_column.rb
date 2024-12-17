# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDetectedAtFromCreatedAtColumn < BatchedMigrationJob
      operation_name :backfill_vulnerabilities_detected_at
      feature_category :vulnerability_management

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(detected_at: nil).update_all('detected_at = created_at')
        end
      end
    end
  end
end
