# frozen_string_literal: true

module EE
  module NotificationSetting
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :email_events
      def email_events(source = nil)
        result = super.dup

        case target
        when Group, :group
          result << :new_epic
        end

        result
      end
    end
  end
end
