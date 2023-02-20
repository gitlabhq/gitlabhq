# frozen_string_literal: true

#
# Used by NotificationService to determine who should receive notification
#
module NotificationRecipients
  module BuildService
    def self.notifiable_users(users, *args)
      users.compact.map { |u| NotificationRecipient.new(u, *args) }.select(&:notifiable?).map(&:user)
    end

    def self.notifiable?(user, *args)
      NotificationRecipient.new(user, *args).notifiable?
    end

    def self.build_recipients(target, current_user, **args)
      ::NotificationRecipients::Builder::Default.new(target, current_user, **args).notification_recipients
    end

    def self.build_new_note_recipients(...)
      ::NotificationRecipients::Builder::NewNote.new(...).notification_recipients
    end

    def self.build_merge_request_unmergeable_recipients(...)
      ::NotificationRecipients::Builder::MergeRequestUnmergeable.new(...).notification_recipients
    end

    def self.build_project_maintainers_recipients(target, **args)
      ::NotificationRecipients::Builder::ProjectMaintainers.new(target, **args).notification_recipients
    end

    def self.build_new_review_recipients(...)
      ::NotificationRecipients::Builder::NewReview.new(...).notification_recipients
    end

    def self.build_requested_review_recipients(...)
      ::NotificationRecipients::Builder::RequestReview.new(...).notification_recipients
    end
  end
end
