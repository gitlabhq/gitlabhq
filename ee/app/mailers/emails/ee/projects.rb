module Emails
  module EE
    module Projects
      def mirror_was_hard_failed_email(project_id, user_id)
        @project = Project.find(project_id)
        user = User.find(user_id)

        mail(to: user.notification_email,
             subject: subject('Repository mirroring paused'))
      end

      def project_mirror_user_changed_email(new_mirror_user_id, deleted_user_name, project_id)
        @project = Project.find(project_id)
        @deleted_user_name = deleted_user_name
        new_mirror_user = User.find(new_mirror_user_id)

        mail(to: new_mirror_user.notification_email,
             subject: subject('Mirror user changed'))
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def prometheus_alert_fired_email(project_id, user_id, alert_params)
        alert_metric_id = alert_params["labels"]["gitlab_alert_id"]

        @project = Project.find_by(id: project_id)
        return unless @project

        @alert = @project.prometheus_alerts.find_by(prometheus_metric: alert_metric_id)
        return unless @alert

        @environment = @alert.environment

        user = User.find_by(id: user_id)
        return unless user

        subject_text = "Alert: #{@environment.name} - #{@alert.title} #{@alert.computed_operator} #{@alert.threshold} for 5 minutes"

        mail(to: user.notification_email, subject: subject(subject_text))
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
