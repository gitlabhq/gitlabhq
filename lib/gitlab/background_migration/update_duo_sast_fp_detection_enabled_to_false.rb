# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateDuoSastFpDetectionEnabledToFalse < BatchedMigrationJob
      operation_name :update_all
      feature_category :vulnerability_management

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(duo_sast_fp_detection_enabled: true)
                   .update_all(duo_sast_fp_detection_enabled: false)
        end
      end
    end
  end
end
