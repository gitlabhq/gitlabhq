# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class RequestReview < Base
      attr_reader :merge_request, :current_user, :reviewer

      def initialize(merge_request, current_user, reviewer)
        @merge_request = merge_request
        @current_user = current_user
        @reviewer = reviewer
      end

      def target
        merge_request
      end

      def build!
        add_recipients(reviewer, :mention, NotificationReason::REVIEW_REQUESTED)
      end
    end
  end
end
