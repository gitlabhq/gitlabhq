# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class Default < Base
      MENTION_TYPE_ACTIONS = [:new_issue, :new_merge_request].freeze

      attr_reader :target
      attr_reader :current_user
      attr_reader :action
      attr_reader :previous_assignees
      attr_reader :skip_current_user

      def initialize(target, current_user, action:, custom_action: nil, previous_assignees: nil, skip_current_user: true)
        @target = target
        @current_user = current_user
        @action = action
        @custom_action = custom_action
        @previous_assignees = previous_assignees
        @skip_current_user = skip_current_user
      end

      def add_watchers
        add_project_watchers
      end

      def build!
        add_participants(current_user)
        add_watchers
        add_custom_notifications

        # Re-assign is considered as a mention of the new assignee
        case custom_action
        when :reassign_merge_request, :reassign_issue
          add_recipients(previous_assignees, :mention, nil)
          add_recipients(target.assignees, :mention, NotificationReason::ASSIGNED)
        when :change_reviewer_merge_request
          add_recipients(previous_assignees, :mention, nil)
          add_recipients(target.reviewers, :mention, NotificationReason::REVIEW_REQUESTED)
        end

        add_subscribed_users

        if self.class.mention_type_actions.include?(custom_action)
          # These will all be participants as well, but adding with the :mention
          # type ensures that users with the mention notification level will
          # receive them, too.
          add_mentions(current_user, target: target)

          # We use the `:participating` notification level in order to match existing legacy behavior as captured
          # in existing specs (notification_service_spec.rb ~ line 507)
          if target.is_a?(Issuable)
            add_recipients(target.assignees, :participating, NotificationReason::ASSIGNED)
          end

          add_labels_subscribers
        end
      end

      def acting_user
        current_user if skip_current_user
      end

      # Build event key to search on custom notification level
      # Check NotificationSetting.email_events
      def custom_action
        @custom_action ||= "#{action}_#{target.class.model_name.name.underscore}".to_sym
      end

      def self.mention_type_actions
        MENTION_TYPE_ACTIONS.dup
      end
    end
  end
end

NotificationRecipients::Builder::Default.prepend_mod_with('NotificationRecipients::Builder::Default')
