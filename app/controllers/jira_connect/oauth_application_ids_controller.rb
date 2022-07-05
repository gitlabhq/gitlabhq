# frozen_string_literal: true

module JiraConnect
  class OauthApplicationIdsController < ::ApplicationController
    feature_category :integrations

    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    def show
      if show_application_id?
        render json: { application_id: jira_connect_application_key }
      else
        head :not_found
      end
    end

    private

    def show_application_id?
      return if Gitlab.com?

      Feature.enabled?(:jira_connect_oauth_self_managed) && jira_connect_application_key.present?
    end

    def jira_connect_application_key
      Gitlab::CurrentSettings.jira_connect_application_key.presence
    end
  end
end
