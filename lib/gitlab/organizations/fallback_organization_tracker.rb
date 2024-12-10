# frozen_string_literal: true

module Gitlab
  module Organizations
    class FallbackOrganizationTracker
      def self.without_tracking
        previous_value = current_value
        disable
        yield
      ensure
        set(previous_value)
      end

      def self.enable
        set(true)
      end

      def self.disable
        set(false)
      end

      def self.enabled?
        current_value == true
      end

      def self.trigger
        return unless enabled? && Feature.enabled?(:track_organization_fallback, Feature.current_request)

        Gitlab::InternalEvents.track_event(
          'fallback_current_organization_to_default',
          category: 'Organizations',
          additional_properties: {
            label: Gitlab::ApplicationContext.current_context_attribute(:caller_id)
          }
        )
      end

      class << self
        private

        def current_value
          Gitlab::SafeRequestStore[:fallback_organization_used]
        end

        def set(value)
          Gitlab::SafeRequestStore.write(:fallback_organization_used, value)
        end
      end
    end
  end
end
