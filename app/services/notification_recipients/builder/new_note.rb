# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class NewNote < Base
      attr_reader :note

      def initialize(note)
        @note = note
      end

      def target
        note.noteable
      end

      def recipients_target
        note
      end

      # NOTE: may be nil, in the case of a PersonalSnippet
      #
      # (this is okay because NotificationRecipient is written
      # to handle nil projects)
      def project
        note.project
      end

      def group
        if note.for_project_noteable?
          project.group
        else
          target.try(:group) || target.try(:namespace)
        end
      end

      def build!
        # Add all users participating in the thread (author, assignee, comment authors)
        add_participants(note.author)
        add_mentions(note.author, target: note)

        if note.for_project_noteable?
          # Merge project watchers
          add_project_watchers
        else
          add_group_watchers
        end

        add_custom_notifications
        add_subscribed_users
      end

      def custom_action
        :new_note
      end

      def acting_user
        note.author
      end
    end
  end
end
