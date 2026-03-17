# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RemoveVersionFromUserDetailsOnboardingStatus < BatchedMigrationJob
      operation_name :remove_version_from_onboarding_status
      feature_category :onboarding

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where("onboarding_status ? 'version'")
            .update_all("onboarding_status = onboarding_status - 'version'")
        end
      end
    end
  end
end
