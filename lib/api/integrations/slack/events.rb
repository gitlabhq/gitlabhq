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

        before do
          Gitlab::ApplicationContext.push(client_type: 'integration', client_name: 'slack')
        end

        namespace 'integrations/slack' do
          desc 'Receive Slack events' do
            success [
              { code: 200, message: 'Successfully processed event' },
              { code: 204, message: 'Failed to process event' }
            ]
            failure [
              { code: 401, message: 'Unauthorized' }
            ]
            tags ['integrations']
          end

          # Params are based on the JSON schema spec for Slack events https://api.slack.com/types/event.
          # We mark all params as `optional` as we never want to fail a request from Slack. Slack may remove
          # deprecated params in future that are currently described in their JSON schema spec as required.
          params do
            optional :token, type: String, desc: 'Request token. Not used by GitLab. Deprecated by Slack.'
            optional :team_id, type: String, desc: 'ID of the Slack workspace where the event occurred.'
            optional :api_app_id, type: String, desc: 'ID of the Slack app.'
            optional :event, type: Hash, desc: 'Event object with variable properties.'
            optional :type, type: String, desc: 'Type of the event, usually `event_callback`.'
            optional :event_id, type: String, desc: 'ID of the event.'
            optional :event_time, type: Integer, desc: 'Unix timestamp, in seconds, of when the event was dispatched.'
            optional :authed_users, type: Array[String], desc: 'Array of Slack user IDs. Deprecated by Slack.'
          end

          route_setting :authorization, skip_granular_token_authorization: :slack_signature_auth
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
