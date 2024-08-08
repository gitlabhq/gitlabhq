# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class AlterWebhookDeletedAuditEvent < Gitlab::BackgroundMigration::BatchedMigrationJob
      include Gitlab::Database::DynamicModelHelpers

      feature_category :webhooks
      operation_name :alter_webhook_deleted_audit_event

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(target_type: %w[SystemHook GroupHook ProjectHook])
            .where("target_details NOT LIKE 'Hook%'")
            .update_all("target_details = regexp_replace(target_details, '.*', 'Hook ' || target_id::text)")
        end
      end
    end
  end
end
