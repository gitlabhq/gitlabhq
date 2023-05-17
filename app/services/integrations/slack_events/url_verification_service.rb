# frozen_string_literal: true

# Returns the special URL verification response expected by Slack when the
# GitLab Slack app is first configured to receive Slack events.
#
# Slack will issue the challenge request to the endpoint that receives events
# and expect it to respond with same the `challenge` param back.
#
# See https://api.slack.com/apis/connections/events-api.
module Integrations
  module SlackEvents
    class UrlVerificationService
      def initialize(params)
        @challenge = params[:challenge]
      end

      def execute
        { challenge: challenge }
      end

      private

      attr_reader :challenge
    end
  end
end
