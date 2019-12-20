# frozen_string_literal: true

module Gitlab
  # This class implements a simple rate limiter that can be used to throttle
  # certain actions. Unlike Rack Attack and Rack::Throttle, which operate at
  # the middleware level, this can be used at the controller or API level.
  #
  # @example
  #  if Gitlab::ApplicationRateLimiter.throttled?(:project_export, scope: [@project, @current_user])
  #   flash[:alert] = 'error!'
  #   redirect_to(edit_project_path(@project), status: :too_many_requests)
  # end
  class ApplicationRateLimiter
    class << self
      # Application rate limits
      #
      # Threshold value can be either an Integer or a Proc
      # in order to not evaluate it's value every time this method is called
      # and only do that when it's needed.
      def rate_limits
        {
          project_export:              { threshold: 1, interval: 5.minutes },
          project_download_export:     { threshold: 10, interval: 10.minutes },
          project_generate_new_export: { threshold: 1, interval: 5.minutes },
          play_pipeline_schedule:      { threshold: 1, interval: 1.minute },
          show_raw_controller:         { threshold: -> { Gitlab::CurrentSettings.current_application_settings.raw_blob_request_limit }, interval: 1.minute }
        }.freeze
      end

      # Increments the given key and returns true if the action should
      # be throttled.
      #
      # @param key [Symbol] Key attribute registered in `.rate_limits`
      # @option scope [Array<ActiveRecord>] Array of ActiveRecord models to scope throttling to a specific request (e.g. per user per project)
      # @option threshold [Integer] Optional threshold value to override default one registered in `.rate_limits`
      # @option interval [Integer] Optional interval value to override default one registered in `.rate_limits`
      #
      # @return [Boolean] Whether or not a request should be throttled
      def throttled?(key, scope: nil, interval: nil, threshold: nil)
        return unless rate_limits[key]

        threshold_value = threshold || threshold(key)

        threshold_value > 0 &&
          increment(key, scope, interval) > threshold_value
      end

      # Increments the given cache key and increments the value by 1 with the
      # expiration interval defined in `.rate_limits`.
      #
      # @param key [Symbol] Key attribute registered in `.rate_limits`
      # @option scope [Array<ActiveRecord>] Array of ActiveRecord models to scope throttling to a specific request (e.g. per user per project)
      # @option interval [Integer] Optional interval value to override default one registered in `.rate_limits`
      #
      # @return [Integer] incremented value
      def increment(key, scope, interval = nil)
        value = 0
        interval_value = interval || interval(key)

        Gitlab::Redis::Cache.with do |redis|
          cache_key = action_key(key, scope)
          value     = redis.incr(cache_key)
          redis.expire(cache_key, interval_value) if value == 1
        end

        value
      end

      # Logs request using provided logger
      #
      # @param request [Http::Request] - Web request to be logged
      # @param type [Symbol] A symbol key that represents the request
      # @param current_user [User] Current user of the request, it can be nil
      # @param logger [Logger] Logger to log request to a specific log file. Defaults to Gitlab::AuthLogger
      def log_request(request, type, current_user, logger = Gitlab::AuthLogger)
        request_information = {
          message:        'Application_Rate_Limiter_Request',
          env:            type,
          remote_ip:      request.ip,
          request_method: request.request_method,
          path:           request.fullpath
        }

        if current_user
          request_information.merge!({
                                       user_id:  current_user.id,
                                       username: current_user.username
                                     })
        end

        logger.error(request_information)
      end

      private

      def threshold(key)
        value = rate_limit_value_by_key(key, :threshold)

        return value.call if value.is_a?(Proc)

        value.to_i
      end

      def interval(key)
        rate_limit_value_by_key(key, :interval).to_i
      end

      def rate_limit_value_by_key(key, setting)
        action = rate_limits[key]

        action[setting] if action
      end

      def action_key(key, scope)
        composed_key = [key, scope].flatten.compact

        serialized = composed_key.map do |obj|
          if obj.is_a?(String) || obj.is_a?(Symbol)
            "#{obj}"
          else
            "#{obj.class.model_name.to_s.underscore}:#{obj.id}"
          end
        end.join(":")

        "application_rate_limiter:#{serialized}"
      end
    end
  end
end
