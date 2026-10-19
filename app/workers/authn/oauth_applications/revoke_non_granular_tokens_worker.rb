# frozen_string_literal: true

module Authn
  module OauthApplications
    class RevokeNonGranularTokensWorker
      include ApplicationWorker

      idempotent!
      deduplicate :until_executing
      data_consistency :sticky
      feature_category :permissions
      concurrency_limit -> { 200 }
      defer_on_database_health_signal :gitlab_main_org, [:oauth_access_tokens, :oauth_access_grants], 5.minutes

      def perform(application_id, user_id)
        user = User.find_by_id(user_id)
        return unless user

        Authn::OauthApplication.revoke_non_granular_tokens_and_grants_for(application_id, user)
      end
    end
  end
end
