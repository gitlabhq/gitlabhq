# frozen_string_literal: true

# Shared concern for controllers to handle editing the GitLab for Slack app
# integration at project, group and instance-levels.
#
# Controllers should define these methods:
# - `#integration` to return the Integrations::GitLabSlackApplication record.
# - `#redirect_to_integration_page` to redirect to the integration edit page
module Integrations
  module SlackControllerSettings
    extend ActiveSupport::Concern

    included do
      feature_category :integrations
    end

    def destroy
      slack_integration.destroy

      redirect_to_integration_page
    end

    private

    def slack_integration
      @slack_integration ||= integration.slack_integration
    end
  end
end
