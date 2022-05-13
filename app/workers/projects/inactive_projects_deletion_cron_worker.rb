# frozen_string_literal: true

module Projects
  class InactiveProjectsDeletionCronWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize
    include CronjobQueue

    idempotent!
    data_consistency :always
    feature_category :compliance_management

    INTERVAL = 2.seconds.to_i

    def perform
      return unless ::Gitlab::CurrentSettings.delete_inactive_projects?

      admin_user = User.admins.active.first

      return unless admin_user

      notified_inactive_projects = Gitlab::InactiveProjectsDeletionWarningTracker.notified_projects

      Project.inactive.without_deleted.find_each(batch_size: 100).with_index do |project, index| # rubocop: disable CodeReuse/ActiveRecord
        next unless Feature.enabled?(:inactive_projects_deletion, project.root_namespace)

        delay = index * INTERVAL

        with_context(project: project, user: admin_user) do
          deletion_warning_email_sent_on = notified_inactive_projects["project:#{project.id}"]

          if send_deletion_warning_email?(deletion_warning_email_sent_on, project)
            send_notification(delay, project, admin_user)
          elsif deletion_warning_email_sent_on && delete_due_to_inactivity?(deletion_warning_email_sent_on)
            Gitlab::InactiveProjectsDeletionWarningTracker.new(project.id).reset
            delete_project(project, admin_user)
          end
        end
      end
    end

    private

    def grace_months_after_deletion_notification
      strong_memoize(:grace_months_after_deletion_notification) do
        (::Gitlab::CurrentSettings.inactive_projects_delete_after_months -
          ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months).months
      end
    end

    def send_deletion_warning_email?(deletion_warning_email_sent_on, project)
      deletion_warning_email_sent_on.blank?
    end

    def delete_due_to_inactivity?(deletion_warning_email_sent_on)
      deletion_warning_email_sent_on < grace_months_after_deletion_notification.ago
    end

    def deletion_date
      grace_months_after_deletion_notification.from_now.to_date.to_s
    end

    def delete_project(project, user)
      ::Projects::DestroyService.new(project, user, {}).async_execute
    end

    def send_notification(delay, project, user)
      ::Projects::InactiveProjectsDeletionNotificationWorker.perform_in(delay, project.id, deletion_date)
    end
  end
end

Projects::InactiveProjectsDeletionCronWorker.prepend_mod
