# frozen_string_literal: true

module API
  class Integrations
    module Slack
      class Events
        class UrlVerification
          # When the GitLab Slack app is first configured to receive Slack events,
          # Slack will issue a special request to the endpoint and expect it to respond
          # with the `challenge` param.
          #
          # This must be done in-request, rather than on a queue.
          #
          # See https://api.slack.com/apis/connections/events-api.
          def self.call(params)
            { challenge: params[:challenge] }
          end
        end
      end
    end
  end
end
