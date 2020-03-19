# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class NewRelease < Base
      attr_reader :target

      def initialize(target)
        @target = target
      end

      def build!
        add_recipients(target.project.authorized_users, :custom, nil)
      end

      def custom_action
        :new_release
      end

      def acting_user
        target.author
      end
    end
  end
end
