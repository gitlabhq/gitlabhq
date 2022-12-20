# frozen_string_literal: true

module JiraConnect
  class OauthApplicationIdsController < ApplicationController
    feature_category :integrations

    skip_before_action :verify_atlassian_jwt!

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

      jira_connect_application_key.present?
    end

    def jira_connect_application_key
      Gitlab::CurrentSettings.jira_connect_application_key.presence
    end
  end
end
