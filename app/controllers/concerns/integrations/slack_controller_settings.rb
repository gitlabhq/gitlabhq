# frozen_string_literal: true

# Shared concern for controllers to handle editing the GitLab for Slack app
# integration at project, group and instance-levels.
#
# Controllers should define these methods:
# - `#integration` to return the Integrations::GitLabSlackApplication record.
# - `#redirect_to_integration_page` to redirect to the integration edit page.
# - `#installation_service` to return a service class to handle the OAuth flow.
module Integrations
  module SlackControllerSettings
    extend ActiveSupport::Concern

    included do
      feature_category :integrations

      before_action :handle_oauth_error, only: :slack_auth
      before_action :check_oauth_state, only: :slack_auth
    end

    def slack_auth
      result = installation_service.execute

      flash[:alert] = result.message if result.error?

      session[:slack_install_success] = result.success?
      redirect_to_integration_page
    end

    def destroy
      slack_integration.destroy

      PropagateIntegrationWorker.perform_async(integration.id) unless integration.project_level?

      redirect_to_integration_page
    end

    private

    def slack_integration
      @slack_integration ||= integration.slack_integration
    end

    def handle_oauth_error
      return unless params[:error] == 'access_denied'

      flash[:alert] = s_('SlackIntegration|Access request canceled')
      redirect_to_integration_page
    end

    def check_oauth_state
      render_403 unless valid_authenticity_token?(session, params[:state])

      true
    end
  end
end
