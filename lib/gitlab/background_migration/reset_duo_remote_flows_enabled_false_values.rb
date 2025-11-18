# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ResetDuoRemoteFlowsEnabledFalseValues < BatchedMigrationJob
      operation_name :update_all
      feature_category :duo_agent_platform

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(duo_remote_flows_enabled: false)
                   .update_all(duo_remote_flows_enabled: nil)
        end
      end
    end
  end
end
