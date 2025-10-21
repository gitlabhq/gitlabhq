# frozen_string_literal: true

module Gitlab
  module Middleware
    # JsonValidation middleware provides JSON request validation with configurable limits.
    #
    # Features:
    # - Global validation limits for all JSON requests
    # - Route-specific limits that override global defaults for matching paths
    # - Multiple validation modes: :enforced, :logging, :disabled
    # - Configurable limits for depth, array size, hash size, total elements, and body size
    class JsonValidation
      RACK_ENV_METADATA_KEY = "gitlab.json.validation.metadata"

      COLLECT_EVENTS_PATH = %r{
        \A/-/collect_events\z
      }xi

      TERRAFORM_STATE_PATH = %r{
        \A/api/v4/projects/
        (?<id>
        [a-zA-Z0-9%-._]{1,255}
        )/terraform/state/
      }xi

      NPM_INSTANCE_PACKAGES_PATH = %r{
        \A/api/v4/packages/npm/-/npm/v1/security/
        (?:(?:advisories/bulk)|(?:audits/quick))\z
      }xi

      NPM_GROUP_PACKAGES_PATH = %r{
        \A/api/v4/groups/
        (?<id>
        [a-zA-Z0-9%-._]{1,255}
        )/-/packages/npm/-/npm/v1/security/
        (?:(?:advisories/bulk)|(?:audits/quick))\z
      }xi

      NPM_PROJECT_PACKAGES_PATH = %r{
        \A/api/v4/projects/
        (?<id>
        [a-zA-Z0-9%-._]{1,255}
        )/packages/npm/-/npm/v1/security/
        (?:(?:advisories/bulk)|(?:audits/quick))\z
      }xi

      INTERNAL_API_PATH = %r{
        \A/api/v4/internal/
      }xi

      DUO_WORKFLOW_PATH = %r{
        \A/api/v4/ai/duo_workflows/workflows/
      }xi

      DEFAULT_LIMITS = {
        # Rack::Utils uses a depth of 32 by default
        max_depth: ENV.fetch('GITLAB_JSON_MAX_DEPTH', 32).to_i,
        max_array_size: ENV.fetch('GITLAB_JSON_MAX_ARRAY_SIZE', 50000).to_i,
        max_hash_size: ENV.fetch('GITLAB_JSON_MAX_HASH_SIZE', 50000).to_i,
        max_total_elements: ENV.fetch('GITLAB_JSON_MAX_TOTAL_ELEMENTS', 100000).to_i,
        # Disabled by default because some endpoints upload large payloads
        max_json_size_bytes: ENV.fetch('GITLAB_JSON_MAX_JSON_SIZE_BYTES', 0).to_i,
        # Supported modes: enforced, disabled, logging
        mode: ENV.fetch('GITLAB_JSON_VALIDATION_MODE', 'enforced').downcase.to_sym
      }.freeze

      ROUTE_CONFIGS = [
        # Stricter limits for collect_events endpoint
        {
          regex: COLLECT_EVENTS_PATH,
          methods: %i[post],
          limits: DEFAULT_LIMITS.merge({
            max_json_size_bytes: 10.megabytes
          })
        },
        # The application setting max_terraform_state_size_bytes limits this file size already
        {
          regex: TERRAFORM_STATE_PATH,
          methods: %i[post],
          limits: {
            max_depth: 64,
            max_array_size: 50000,
            max_hash_size: 50000,
            max_total_elements: 250000,
            max_json_size_bytes: 50.megabytes,
            mode: :logging
          }
        },
        # CompressedJson middleware limits NPM sizes already
        {
          regex: NPM_INSTANCE_PACKAGES_PATH,
          methods: %i[post],
          limits: {
            max_depth: 32,
            max_array_size: 50000,
            max_hash_size: 50000,
            max_total_elements: 250000,
            max_json_size_bytes: 50.megabytes,
            mode: :enforced
          }
        },
        {
          regex: NPM_GROUP_PACKAGES_PATH,
          methods: %i[post],
          limits: {
            max_depth: 32,
            max_array_size: 50000,
            max_hash_size: 50000,
            max_total_elements: 250000,
            max_json_size_bytes: 50.megabytes,
            mode: :enforced
          }
        },
        {
          regex: NPM_PROJECT_PACKAGES_PATH,
          methods: %i[post],
          limits: {
            max_depth: 32,
            max_array_size: 50000,
            max_hash_size: 50000,
            max_total_elements: 250000,
            max_json_size_bytes: 50.megabytes,
            mode: :enforced
          }
        },
        # Internal APIs
        {
          regex: INTERNAL_API_PATH,
          methods: %i[post],
          limits: {
            max_depth: 32,
            max_array_size: 50000,
            max_hash_size: 50000,
            max_total_elements: 0, # Regularly exceeds 10,000, disable for now
            max_json_size_bytes: 10.megabytes,
            mode: :enforced
          }
        },
        # Duo Workflow API
        {
          regex: DUO_WORKFLOW_PATH,
          methods: %i[post],
          limits: {
            max_depth: 32,
            max_array_size: 5000,
            max_hash_size: 5000,
            max_total_elements: 0, # Regularly exceeds 10,000, disable for now
            max_json_size_bytes: 25.megabytes,
            mode: :enforced
          }
        }
      ].freeze

      def initialize(app, options = {})
        @app = app
        @default_limits = options[:default_limits] ? DEFAULT_LIMITS.merge(options[:default_limits]) : DEFAULT_LIMITS
        @route_config_map = build_route_config_map(options[:route_limits])
      end

      def call(env)
        return @app.call(env) if global_disabled?

        request = Rack::Request.new(env)

        return @app.call(env) unless json_request?(request)

        limits = limits_for_request(request)
        return @app.call(env) if disabled_mode?(limits)

        allow_if_validated(env, request, limits)
      end

      private

      def global_logging?
        global_validation_mode == :logging
      end

      def global_disabled?
        global_validation_mode == :disabled
      end

      def global_validation_mode
        ENV['GITLAB_JSON_GLOBAL_VALIDATION_MODE']&.to_sym
      end

      def allow_if_validated(env, request, limits)
        validate_json_request!(env, request, limits)
        @app.call(env)
      rescue ::Gitlab::Json::StreamValidator::LimitExceededError => ex
        log_exceeded(ex, request, limits)

        return error_response(ex, 400) unless logging_mode?(limits)

        @app.call(env)
      end

      def relative_url
        File.join('', Gitlab.config.gitlab.relative_url_root).chomp('/')
      end

      def build_route_config_map(custom_route_limits = nil)
        return ROUTE_CONFIGS unless custom_route_limits

        configs = ROUTE_CONFIGS.dup

        # Merge custom limits, with custom taking precedence over defaults
        custom_route_limits.each do |custom_config|
          existing_index = configs.find_index { |config| config[:regex] == custom_config[:regex] }

          if existing_index
            configs[existing_index] = custom_config
          else
            configs << custom_config
          end
        end

        configs
      end

      def limits_for_request(request)
        path = request.path.delete_prefix(relative_url)
        request_method = request.request_method.downcase.to_sym

        route_config = @route_config_map.find do |config|
          regex = config[:regex]
          methods = config[:methods]

          next false if methods&.exclude?(request_method)

          regex.match?(path)
        end

        route_config ? route_config[:limits] : @default_limits
      end

      def log_exceeded(ex, request, limits)
        payload = limits.merge({
          class_name: self.class.name,
          message: ex.to_s,
          method: request.request_method,
          path: request.path,
          ua: request.env["HTTP_USER_AGENT"],
          remote_ip: request.ip
        })

        # Manually add the status code here because the original requests are not
        # logged in production_json.log or api_json.log.
        payload[:status] = 400 unless logging_mode?(limits)

        ::Gitlab::InstrumentationHelper.add_instrumentation_data(payload)
        Gitlab::AppLogger.warn(payload)
      end

      def disabled_mode?(limits)
        limits[:mode] == :disabled
      end

      def logging_mode?(limits)
        limits[:mode] == :logging || global_logging?
      end

      def json_request?(request)
        # Ensure we get synonyms registered in config/initializers/mime_types
        Mime[:json] == request.media_type
      end

      # JSON Validation using Oj streaming
      def validate_json_request!(env, request, limits)
        body = request.body.read
        request.body.rewind

        return if body.empty?

        handler = ::Gitlab::Json::StreamValidator.new(limits)
        handler.sc_parse(body)
      # Could be either a Oj::ParseError or an EncodingError depending on
      # whether mimic_JSON has been called.
      rescue Oj::ParseError, EncodingError
        # If this string isn't valid JSON, let it go
        nil
      ensure
        store_metadata(env, handler)
      end

      def store_metadata(env, handler)
        metadata = handler&.metadata

        return unless metadata

        env[RACK_ENV_METADATA_KEY] = metadata
      end

      def error_response(error, status)
        message = ::Gitlab::Json::StreamValidator.user_facing_error_message(error)

        [
          status,
          { 'Content-Type' => 'application/json' },
          [{ error: message }.to_json]
        ]
      end
    end
  end
end
