# frozen_string_literal: true

# This API endpoint handles all events sent from Slack once a Slack
# workspace has installed the GitLab Slack app.
#
# See https://api.slack.com/apis/connections/events-api.
module API
  class Integrations
    module Slack
      class Events < ::API::Base
        include Slack::Concerns::VerifiesRequest

        feature_category :integrations

        namespace 'integrations/slack' do
          desc 'Receive Slack events' do
            success [
              { code: 200, message: 'Successfully processed event' },
              { code: 204, message: 'Failed to process event' }
            ]
            failure [
              { code: 401, message: 'Unauthorized' }
            ]
          end

          # Params are based on the JSON schema spec for Slack events https://api.slack.com/types/event.
          # We mark all params as `optional` as we never want to fail a request from Slack. Slack may remove
          # deprecated params in future that are currently described in their JSON schema spec as required.
          params do
            optional :token, type: String, desc: '(Deprecated by Slack) The request token, unused by GitLab'
            optional :team_id, type: String, desc: 'The Slack workspace ID of where the event occurred'
            optional :api_app_id, type: String, desc: 'The Slack app ID'
            optional :event, type: Hash, desc: 'The event object with variable properties'
            optional :type, type: String, desc: 'The kind of event this is, usually `event_callback`'
            optional :event_id, type: String, desc: 'A unique identifier for this specific event'
            optional :event_time, type: Integer, desc: 'The epoch timestamp in seconds when this event was dispatched'
            optional :authed_users, type: Array[String], desc: '(Deprecated by Slack) An array of Slack user IDs'
          end

          post :events do
            response = ::Integrations::SlackEventService.new(params).execute

            status :ok

            response.payload
          rescue StandardError => e
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
