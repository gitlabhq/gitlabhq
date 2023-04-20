# frozen_string_literal: true

module Gitlab
  module Harbor
    class Client
      Error = Class.new(StandardError)
      ConfigError = Class.new(Error)

      attr_reader :integration

      def initialize(integration)
        raise ConfigError, 'Please check your integration configuration.' unless integration

        @integration = integration
      end

      def check_project_availability
        options = { headers: headers.merge!('Accept': 'application/json') }
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
          body: Gitlab::Json.parse(response.body),
          total_count: response.headers['x-total-count'].to_i
        }
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
          'Authorization': "Basic #{auth}"
        }
      end
    end
  end
end
