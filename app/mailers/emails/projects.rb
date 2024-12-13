# frozen_string_literal: true

module Emails
  module Projects
    def project_was_moved_email(project_id, user_id, old_path_with_namespace)
      @current_user = @user = User.find user_id
      @project = Project.find project_id
      @target_url = project_url(@project)
      @old_path_with_namespace = old_path_with_namespace
      email_with_layout(
        to: @user.notification_email_for(@project.group),
        subject: subject("Project was moved")
      )
    end

    def project_was_exported_email(current_user, project)
      @project = project
      email_with_layout(
        to: current_user.notification_email_for(project.group),
        subject: subject("Project was exported")
      )
    end

    def project_was_not_exported_email(current_user, project, errors)
      @project = project
      @errors = errors
      email_with_layout(
        to: current_user.notification_email_for(@project.group),
        subject: subject("Project export error")
      )
    end

    def repository_cleanup_success_email(project, user)
      @project = project
      @user = user

      mail_with_locale(
        to: user.notification_email_for(project.group),
        subject: subject("Project cleanup has completed")
      )
    end

    def repository_cleanup_failure_email(project, user, error)
      @project = project
      @user = user
      @error = error

      mail_with_locale(to: user.notification_email_for(project.group), subject: subject("Project cleanup failure"))
    end

    def repository_rewrite_history_success_email(project, user)
      @project = project

      email_with_layout(
        to: user.notification_email_for(project.group),
        subject: subject("Project history rewrite has completed")
      )
    end

    def repository_rewrite_history_failure_email(project, user, error)
      @project = project
      @error = error

      email_with_layout(
        to: user.notification_email_for(project.group),
        subject: subject("Project history rewrite failure")
      )
    end

    def repository_push_email(project_id, opts = {})
      @message =
        Gitlab::Email::Message::RepositoryPush.new(self, project_id, opts)

      # used in notify layout
      @target_url = @message.target_url
      @project = Project.find(project_id)
      @diff_notes_disabled = true

      add_project_headers
      headers['X-GitLab-Author'] = @message.author_username

      mail_with_locale(
        from: sender(@message.author_id, send_from_user_email: @message.send_from_committer_email?),
        reply_to: @message.reply_to,
        subject: subject_with_suffix([@message.subject])
      )
    end

    def prometheus_alert_fired_email(project, user, alert)
      @project = project
      @alert = alert.present
      @incident = alert.issue

      add_project_headers
      add_alert_headers

      subject_text = "Alert: #{@alert.email_title}"
      mail_with_locale(to: user.notification_email_for(@project.group), subject: subject(subject_text))
    end

    def inactive_project_deletion_warning_email(project, user, deletion_date)
      @project = project
      @user = user
      @deletion_date = deletion_date
      subject_text = "Action required: Project #{project.name} is scheduled to be deleted on " \
        "#{deletion_date} due to inactivity"

      email_with_layout(
        to: user.notification_email_for(project.group),
        subject: subject(subject_text))
    end

    private

    def add_alert_headers
      return unless @alert

      headers['X-GitLab-Alert-ID'] = @alert.id
      headers['X-GitLab-Alert-IID'] = @alert.iid
      headers['X-GitLab-NotificationReason'] = "alert_#{@alert.state}"

      add_incident_headers
    end

    def add_incident_headers
      return unless @incident

      headers['X-GitLab-Incident-ID'] = @incident.id
      headers['X-GitLab-Incident-IID'] = @incident.iid
    end
  end
end

Emails::Projects.prepend_mod_with('Emails::Projects')
