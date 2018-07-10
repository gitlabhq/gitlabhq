module EE
  module NotifyPreview
    extend ActiveSupport::Concern

    # We need to define the methods on the prepender directly because:
    # https://github.com/rails/rails/blob/3faf7485623da55215d6d7f3dcb2eed92c59c699/actionmailer/lib/action_mailer/preview.rb#L73
    prepended do
      def add_merge_request_approver_email
        Notify.add_merge_request_approver_email(user.id, merge_request.id, user.id).message
      end

      def issues_csv_email
        Notify.issues_csv_email(user, project, '1997,Ford,E350', { truncated: false, rows_expected: 3, rows_written: 3 }).message
      end

      def approved_merge_request_email
        Notify.approved_merge_request_email(user.id, merge_request.id, approver.id).message
      end

      def unapproved_merge_request_email
        Notify.unapproved_merge_request_email(user.id, merge_request.id, approver.id).message
      end

      def mirror_was_hard_failed_email
        Notify.mirror_was_hard_failed_email(project.id, user.id).message
      end

      def project_mirror_user_changed_email
        Notify.project_mirror_user_changed_email(user.id, 'deleted_user_name', project.id).message
      end

      def send_admin_notification
        Notify.send_admin_notification(user.id, 'Email subject from admin', 'Email body from admin').message
      end

      def send_unsubscribed_notification
        Notify.send_unsubscribed_notification(user.id).message
      end

      def service_desk_new_note_email
        cleanup do
          note = create_note(noteable_type: 'Issue', noteable_id: issue.id, note: 'Issue note content')

          Notify.service_desk_new_note_email(issue.id, note.id).message
        end
      end

      def service_desk_thank_you_email
        Notify.service_desk_thank_you_email(issue.id).message
      end
    end

    private

    def approver
      @user ||= User.first
    end
  end
end
