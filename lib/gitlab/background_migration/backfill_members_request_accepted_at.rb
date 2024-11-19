# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMembersRequestAcceptedAt < BatchedMigrationJob
      operation_name :backfill_members_request_accepted_at
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(requested_at: nil)
            .where(invite_token: nil)
            .where(invite_accepted_at: nil)
            .where(request_accepted_at: nil)
            .update_all("request_accepted_at = created_at")
        end
      end
    end
  end
end
