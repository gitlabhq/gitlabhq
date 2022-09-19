# frozen_string_literal: true

module QA
  module Tools
    module Ci
      # Helpers for CI related tasks
      #
      module Helpers
        include Support::API

        # Logger instance
        #
        # @return [Logger]
        def logger
          @logger ||= Gitlab::QA::TestLogger.logger(
            level: Gitlab::QA::Runtime::Env.log_level,
            source: "CI Tools"
          )
        end

        # Api get request
        #
        # @param [String] path
        # @param [Hash] args
        # @return [Hash, Array]
        def api_get(path, **args)
          response = get("#{api_url}/#{path}", { headers: { "PRIVATE-TOKEN" => access_token }, **args })
          response = response.follow_redirection if response.code == Support::API::HTTP_STATUS_PERMANENT_REDIRECT
          raise "Request failed: '#{response.body}'" unless response.code == Support::API::HTTP_STATUS_OK

          args[:raw_response] ? response : parse_body(response)
        end

        # Gitlab api url
        #
        # @return [String]
        def api_url
          @api_url ||= ENV.fetch('CI_API_V4_URL', 'https://gitlab.com/api/v4')
        end

        # Api access token
        #
        # @return [String]
        def access_token
          @access_token ||= ENV.fetch('QA_GITLAB_CI_TOKEN') { raise('Variable QA_GITLAB_CI_TOKEN missing') }
        end
      end
    end
  end
end
