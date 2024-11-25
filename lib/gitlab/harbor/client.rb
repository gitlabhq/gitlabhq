# frozen_string_literal: true

module Gitlab
  module Harbor
    class Client
      Error = Class.new(StandardError)
      ConfigError = Class.new(Error)

      RESPONSE_SIZE_LIMIT = 1.megabyte
      RESPONSE_MEMORY_SIZE_LIMIT = RESPONSE_SIZE_LIMIT * 5

      attr_reader :integration

      def initialize(integration)
        raise ConfigError, 'Please check your integration configuration.' unless integration

        @integration = integration
      end

      def check_project_availability
        options = { headers: headers.merge!(Accept: 'application/json') }
        response = Gitlab::HTTP.head(url("projects?project_name=#{integration.project_name}"), options)

        { success: response.success? }
      end

      def get_repositories(params)
        get(url("projects/#{integration.project_name}/repositories"), params)
      end

      def get_artifacts(params)
        repository_name = params.delete(:repository_name)
        get(url("projects/#{integration.project_name}/repositories/#{repository_name}/artifacts"), params)
      end

      def get_tags(params)
        repository_name = params.delete(:repository_name)
        artifact_name = params.delete(:artifact_name)
        get(
          url("projects/#{integration.project_name}/repositories/#{repository_name}/artifacts/#{artifact_name}/tags"),
          params
        )
      end

      private

      def get(path, params = {})
        options = { headers: headers, query: params }
        response = Gitlab::HTTP.get(path, options)

        raise Gitlab::Harbor::Client::Error, 'request error' unless response.success?

        {
          body: parse_with_size_validation(response.body),
          total_count: response.headers['x-total-count'].to_i
        }
      end

      def parse_with_size_validation(response_body)
        bytesize = response_body.bytesize

        if bytesize > RESPONSE_SIZE_LIMIT
          limit = ActiveSupport::NumberHelper.number_to_human_size(RESPONSE_SIZE_LIMIT)
          message = "API response is too big. Limit is #{limit}. Got #{bytesize} bytes."
          raise Gitlab::Harbor::Client::Error, message
        end

        parsed = Gitlab::Json.parse(response_body)
        return parsed if Gitlab::Utils::DeepSize.new(parsed, max_size: RESPONSE_MEMORY_SIZE_LIMIT).valid?

        limit = ActiveSupport::NumberHelper.number_to_human_size(RESPONSE_MEMORY_SIZE_LIMIT)
        message = "API response memory footprint is too big. Limit is #{limit}."
        raise Gitlab::Harbor::Client::Error, message

      rescue JSON::ParserError
        raise Gitlab::Harbor::Client::Error, 'invalid response format'
      end

      # url must be used within get method otherwise this would avoid validation by GitLab::HTTP
      def url(path)
        base_url = Gitlab::Utils.append_path(integration.url, '/api/v2.0/')
        Gitlab::Utils.append_path(base_url, path)
      end

      def headers
        auth = Base64.strict_encode64("#{integration.username}:#{integration.password}")
        {
          'Content-Type': 'application/json',
          Authorization: "Basic #{auth}"
        }
      end
    end
  end
end
