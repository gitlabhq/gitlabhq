# frozen_string_literal: true

module Gitlab
  module Ci
    class YamlProcessor
      module FeatureFlags
        ACTOR_KEY = 'ci_yaml_processor_feature_flag_actor'
        NO_ACTOR_VALUE = :no_actor

        NoActorError = Class.new(StandardError)
        NO_ACTOR_MESSAGE = "Actor not set. Ensure to call `enabled?` inside `with_actor` block"

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

          private

          def current_actor
            value = Thread.current[ACTOR_KEY] || (raise NoActorError, NO_ACTOR_MESSAGE)
            return if value == NO_ACTOR_VALUE

            value
          rescue NoActorError => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)

            nil
          end
        end
      end
    end
  end
end
