# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module FeatureFlags
        ACTOR_KEY = 'ci_config_feature_flag_actor'
        CORRECT_USAGE_KEY = 'ci_config_feature_flag_correct_usage'
        NO_ACTOR_VALUE = :no_actor
        NO_ACTOR_MESSAGE = "Actor not set. Ensure to call `enabled?` inside `with_actor` block"
        NoActorError = Class.new(StandardError)

        class << self
          # Cache a feature flag actor as thread local variable so
          # we can have it available later with #enabled?
          def with_actor(actor)
            previous = Thread.current[ACTOR_KEY]

            # When actor is `nil` the method `Thread.current[]=` does not
            # create the ACTOR_KEY. Instead, we want to still save an explicit
            # value to know that we are within the `with_actor` block.
            Thread.current[ACTOR_KEY] = actor || NO_ACTOR_VALUE

            yield
          ensure
            Thread.current[ACTOR_KEY] = previous
          end

          # Use this to check if a feature flag is enabled
          def enabled?(feature_flag)
            ::Feature.enabled?(feature_flag, current_actor)
          end

          def ensure_correct_usage
            previous = Thread.current[CORRECT_USAGE_KEY]
            Thread.current[CORRECT_USAGE_KEY] = true

            yield
          ensure
            Thread.current[CORRECT_USAGE_KEY] = previous
          end

          private

          def current_actor
            value = Thread.current[ACTOR_KEY] || (raise NoActorError, NO_ACTOR_MESSAGE)
            return if value == NO_ACTOR_VALUE

            value
          rescue NoActorError => e
            handle_missing_actor(e)

            nil
          end

          def handle_missing_actor(exception)
            if ensure_correct_usage?
              Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception)
            else
              Gitlab::ErrorTracking.track_exception(exception)
            end
          end

          def ensure_correct_usage?
            Thread.current[CORRECT_USAGE_KEY] == true
          end
        end
      end
    end
  end
end
