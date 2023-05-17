# frozen_string_literal: true

# Client for interacting with the Slack API.
# See https://api.slack.com/web.
module Slack
  class API
    BASE_URL = 'https://slack.com/api'
    BASE_HEADERS = { 'Content-Type' => 'application/json; charset=utf-8' }.freeze

    def initialize(slack_installation)
      @token = slack_installation.bot_access_token

      raise ArgumentError, "No token for slack installation #{slack_installation.id}" unless @token
    end

    def post(api_method, payload)
      url = "#{BASE_URL}/#{api_method}"
      headers = BASE_HEADERS.merge('Authorization' => "Bearer #{token}")

      Gitlab::HTTP.post(url, body: payload.to_json, headers: headers)
    end

    private

    attr_reader :token
  end
end
