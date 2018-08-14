# frozen_string_literal: true

module EE
  module NotificationSetting
    extend ActiveSupport::Concern

    EMAIL_EVENTS_MAPPING = {
      ::Group => [:new_epic]
    }.freeze
    FULL_EMAIL_EVENTS = EMAIL_EVENTS_MAPPING.values.flatten.freeze

    class_methods do
      extend ::Gitlab::Utils::Override

      # Update unfound_translations.rb when events are changed
      override :email_events
      def email_events(source = nil)
        result = super.dup

        if source.nil?
          # Global setting
          result.concat(FULL_EMAIL_EVENTS)
        else
          source_class = source.is_a?(Class) ? source : source.class
          EMAIL_EVENTS_MAPPING[source_class]&.tap do |events|
            result.concat(events)
          end
        end

        result
      end
    end
  end
end
