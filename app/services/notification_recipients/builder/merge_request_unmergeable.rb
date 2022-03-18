# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class MergeRequestUnmergeable < Base
      attr_reader :target

      def initialize(merge_request)
        @target = merge_request
      end

      def build!
        target.merge_participants.each do |user|
          add_recipients(user, :participating, nil)
        end
      end

      def custom_action
        :unmergeable_merge_request
      end

      def acting_user
        nil
      end
    end
  end
end
