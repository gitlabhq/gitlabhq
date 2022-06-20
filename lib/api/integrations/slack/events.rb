# frozen_string_literal: true

# This API endpoint handles all events sent from Slack once a Slack
# workspace has installed the GitLab Slack app.
#
# See https://api.slack.com/apis/connections/events-api.
module API
  class Integrations
    module Slack
      class Events < ::API::Base
        feature_category :integrations

        before { verify_slack_request! }

        helpers do
          def verify_slack_request!
            unauthorized! unless Request.verify!(request)
          end
        end

        namespace 'integrations/slack' do
          post :events do
            type = params['type']
            raise ArgumentError, "Unable to handle event type: '#{type}'" unless type == 'url_verification'

            status :ok
            UrlVerification.call(params)
          rescue ArgumentError => e
            # Track the error, but respond with a `2xx` because we don't want to risk
            # Slack rate-limiting, or disabling our app, due to error responses.
            # See https://api.slack.com/apis/connections/events-api.
            Gitlab::ErrorTracking.track_exception(e)

            no_content!
          end
        end
      end
    end
  end
end
