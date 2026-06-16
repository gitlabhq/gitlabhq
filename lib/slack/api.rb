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

      response = Integrations::Clients::HTTP.post(url, body: payload.to_json, headers: headers)
      normalize_response(response)
    end

    def get(api_method, query = {})
      url = "#{BASE_URL}/#{api_method}"
      headers = BASE_HEADERS.merge('Authorization' => "Bearer #{token}")

      Integrations::Clients::HTTP.get(url, query: query, headers: headers)
    end

    def add_reaction(channel:, name:, timestamp:)
      Gitlab::IntegrationsLogger.info(
        message: 'Slack API: adding reaction',
        reaction: name,
        channel_id: channel,
        timestamp: timestamp
      )
      response = post('reactions.add', channel: channel, name: name, timestamp: timestamp)
      log_error('Slack API error when adding reaction', response, channel) unless response['ok']
      response
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      handle_http_error(e, 'Slack API error when adding reaction', channel)
    end

    def remove_reaction(channel:, name:, timestamp:)
      Gitlab::IntegrationsLogger.info(
        message: 'Slack API: removing reaction',
        reaction: name,
        channel_id: channel,
        timestamp: timestamp
      )
      response = post('reactions.remove', channel: channel, name: name, timestamp: timestamp)
      log_error('Slack API error when removing reaction', response, channel) unless response['ok']
      response
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      handle_http_error(e, 'Slack API error when removing reaction', channel)
    end

    def post_ephemeral(channel:, user:, text:)
      Gitlab::IntegrationsLogger.info(
        message: 'Slack API: posting ephemeral',
        channel_id: channel
      )
      response = post('chat.postEphemeral', channel: channel, user: user, text: text)
      log_error('Slack API error when posting ephemeral message', response, channel) unless response['ok']
      response
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      handle_http_error(e, 'Slack API error when posting ephemeral message', channel)
    end

    def post_message(channel:, text:, thread_ts: nil, blocks: nil)
      Gitlab::IntegrationsLogger.info(
        message: 'Slack API: posting message',
        channel_id: channel,
        threaded: thread_ts.present?
      )
      payload = { channel: channel, text: text }
      payload[:thread_ts] = thread_ts if thread_ts.present?
      # [] is intentionally skipped here (never post an empty message);
      # update_message uses `unless blocks.nil?` so it can clear blocks with [].
      payload[:blocks] = blocks if blocks.present?
      response = post('chat.postMessage', payload)
      log_error('Slack API error when posting message', response, channel) unless response['ok']
      response
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      handle_http_error(e, 'Slack API error when posting message', channel)
    end

    # Edits a message in place. Needs only chat:write. Pass blocks: [] to clear
    # existing blocks (omitting the key leaves the prior blocks in place).
    # See https://docs.slack.dev/reference/methods/chat.update
    def update_message(channel:, ts:, text:, blocks: nil)
      Gitlab::IntegrationsLogger.info(
        message: 'Slack API: updating message',
        channel_id: channel
      )
      payload = { channel: channel, ts: ts, text: text }
      payload[:blocks] = blocks unless blocks.nil?
      response = post('chat.update', payload)
      log_error('Slack API error when updating message', response, channel) unless response['ok']
      response
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      handle_http_error(e, 'Slack API error when updating message', channel)
    end

    # Sets a thread's AI status indicator. loading_messages (max 10) auto-rotate
    # as a loading animation; the status clears when the app posts a reply, and
    # otherwise times out after 2 minutes. Needs only chat:write.
    # See https://docs.slack.dev/reference/methods/assistant.threads.setStatus
    def set_status(channel:, thread_ts:, status:, loading_messages: nil)
      Gitlab::IntegrationsLogger.info(
        message: 'Slack API: setting status',
        channel_id: channel
      )
      payload = { channel_id: channel, thread_ts: thread_ts, status: status }
      payload[:loading_messages] = loading_messages if loading_messages.present?
      response = post('assistant.threads.setStatus', payload)
      log_error('Slack API error when setting status', response, channel) unless response['ok']
      response
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      handle_http_error(e, 'Slack API error when setting status', channel)
    end

    private

    attr_reader :token

    def normalize_response(response)
      parsed = response.respond_to?(:parsed_response) ? response.parsed_response : response
      parsed.is_a?(Hash) ? parsed : { 'ok' => false, 'error' => parsed.to_s }
    end

    def handle_http_error(exception, message, channel)
      error_response = { 'ok' => false, 'error' => exception.message }
      log_error(message, error_response, channel)
      error_response
    end

    def log_error(message, response, channel)
      Gitlab::IntegrationsLogger.error(
        message: message,
        channel_id: channel,
        response: response
      )
    end
  end
end
