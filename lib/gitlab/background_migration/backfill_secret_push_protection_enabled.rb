# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSecretPushProtectionEnabled < BatchedMigrationJob
      extend ActiveSupport::Concern

      operation_name :backfill_secret_push_protection_enabled
      feature_category :secret_detection

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(secret_push_protection_enabled: nil)
            .update_all('secret_push_protection_enabled = pre_receive_secret_detection_enabled')
        end
      end
    end
  end
end
