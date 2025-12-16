# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RemoveExperimentsFromUserDetailsOnboardingStatus < BatchedMigrationJob
      operation_name :remove_experiments_from_onboarding_status
      feature_category :onboarding

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where("onboarding_status ? 'experiments'")
            .update_all("onboarding_status = onboarding_status - 'experiments'")
        end
      end
    end
  end
end
