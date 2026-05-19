# frozen_string_literal: true

module Gitlab
  module Ci
    module Matching
      # Parses an environment_key produced by the runner's AutoscalerResumeKey.
      # Format: "<runner_id>/<system_id>/<executor-specific-data>"
      # NOTE: system_id is url-encoded by the runner
      class EnvironmentKey
        MAX_ENVIRONMENT_KEY_LENGTH = 512

        def initialize(environment_key)
          @environment_key = environment_key
        end

        # Returns true if the given runner and runner_manager own this suspended environment.
        # NOTE: This is a JOB ROUTING hint only, not an authorization gate.
        # The environment_key is stored in ci_builds.options[:suspend_options] and is not
        # cryptographically verified. Do NOT use this method to grant
        # capabilities, credentials, or access to resources.
        #
        # system_id is mandatory in the positional format. A key without a system_id
        # segment (fewer than 3 slash-delimited parts) will never match.
        def matches_runner?(runner, runner_manager: nil)
          rid = runner_id
          return false if rid.nil?
          return false unless rid == runner.id

          sid = system_id
          return false if sid.nil?
          return false if runner_manager.nil?

          sid == runner_manager.system_xid
        end

        def runner_id
          parts = parsed_parts
          return unless parts

          id = Integer(parts[0], 10, exception: false)
          id if id&.positive?
        end

        def system_id
          raw = parsed_parts&.at(1).presence
          return unless raw

          CGI.unescape(raw)
        end

        private

        def parsed_parts
          return @parsed_parts if defined?(@parsed_parts)

          @parsed_parts = parse_parts
        end

        def parse_parts
          return unless @environment_key.present?
          return unless @environment_key.length <= MAX_ENVIRONMENT_KEY_LENGTH

          parts = @environment_key.split('/', 3)
          parts if parts.length == 3
        end
      end
    end
  end
end
