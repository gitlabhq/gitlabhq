# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- existing module
  module HttpClient
    DEFAULT_OPTIONS = {
      multipart: true,
      allow_local_requests: true,
      # override default value to be always false to allow clickhouse requests in silent mode
      silent_mode_enabled: false,
      # higher timeout for test environment
      read_timeout: Rails.env.test? ? 60 : Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS[:read_timeout]
    }.freeze

    def self.build_post_proc(**additional_options)
      ->(url, headers, body) do
        options = DEFAULT_OPTIONS.merge(headers: headers, **additional_options)
        options[body.is_a?(IO) ? :body_stream : :body] = body

        response = Gitlab::HTTP.post(url, options)
        ClickHouse::Client::Response.new(response.body, response.code, response.headers)
      end
    end
  end
end
