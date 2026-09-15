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

        response = Gitlab::HTTP.post(with_log_comment(url), options)
        ClickHouse::Client::Response.new(response.body, response.code, response.headers)
      end
    end

    # ClickHouse records this setting in system.query_log, which is what lets a
    # slow query be traced back to the request that issued it. It goes on the URL
    # rather than in the body so the streamed CSV insert (IO body) is covered too.
    def self.with_log_comment(url)
      separator = url.include?('?') ? '&' : '?'

      "#{url}#{separator}log_comment=#{CGI.escape(log_comment)}"
    end

    # Individual attributes are read straight off Labkit::Context rather than via
    # Gitlab::ApplicationContext.current, which materializes the whole hash and
    # forces every lazy lambda. Same tradeoff as Gitlab::QueryLogs::Tags.
    def self.log_comment
      context = Labkit::Context.current

      Gitlab::Json.dump({
        correlation_id: Labkit::Correlation::CorrelationId.current_id,
        user_id: context&.get_attribute(Labkit::Fields::GL_USER_ID),
        root_namespace_id: context&.get_attribute(Labkit::Fields::GL_ROOT_NAMESPACE_ID),
        organization_id: context&.get_attribute(:organization_id),
        application: Gitlab.process_name,
        feature_category: context&.get_attribute(:feature_category)
      }.compact)
    end
  end
end
