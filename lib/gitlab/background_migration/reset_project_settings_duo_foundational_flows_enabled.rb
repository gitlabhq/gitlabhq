# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ResetProjectSettingsDuoFoundationalFlowsEnabled < BatchedMigrationJob
      operation_name :update_all
      feature_category :duo_agent_platform

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where.not(duo_foundational_flows_enabled: nil).update_all(duo_foundational_flows_enabled: nil)
        end
      end
    end
  end
end
