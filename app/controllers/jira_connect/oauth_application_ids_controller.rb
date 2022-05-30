# frozen_string_literal: true

module JiraConnect
  class OauthApplicationIdsController < ::ApplicationController
    feature_category :integrations

    skip_before_action :authenticate_user!

    def show
      if Feature.enabled?(:jira_connect_oauth_self_managed) && jira_connect_application_key.present?
        render json: { application_id: jira_connect_application_key }
      else
        head :not_found
      end
    end

    private

    def jira_connect_application_key
      Gitlab::CurrentSettings.jira_connect_application_key.presence
    end
  end
end
