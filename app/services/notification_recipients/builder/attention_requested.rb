# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class AttentionRequested < Base
      attr_reader :merge_request, :current_user, :user

      def initialize(merge_request, current_user, user)
        @merge_request = merge_request
        @current_user = current_user
        @user = user
      end

      def target
        merge_request
      end

      def build!
        add_recipients(user, :mention, NotificationReason::ATTENTION_REQUESTED)
      end
    end
  end
end
