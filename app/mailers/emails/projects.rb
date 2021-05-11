# frozen_string_literal: true

module Emails
  module Projects
    def project_was_moved_email(project_id, user_id, old_path_with_namespace)
      @current_user = @user = User.find user_id
      @project = Project.find project_id
      @target_url = project_url(@project)
      @old_path_with_namespace = old_path_with_namespace
      mail(to: @user.notification_email_for(@project.group),
           subject: subject("Project was moved"))
    end

    def project_was_exported_email(current_user, project)
      @project = project
      mail(to: current_user.notification_email_for(project.group),
           subject: subject("Project was exported"))
    end

    def project_was_not_exported_email(current_user, project, errors)
      @project = project
      @errors = errors
      mail(to: current_user.notification_email_for(@project.group),
           subject: subject("Project export error"))
    end

    def repository_cleanup_success_email(project, user)
      @project = project
      @user = user

      mail(to: user.notification_email_for(project.group), subject: subject("Project cleanup has completed"))
    end

    def repository_cleanup_failure_email(project, user, error)
      @project = project
      @user = user
      @error = error

      mail(to: user.notification_email_for(project.group), subject: subject("Project cleanup failure"))
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

      mail(from:      sender(@message.author_id, send_from_user_email: @message.send_from_committer_email?),
           reply_to:  @message.reply_to,
           subject:   @message.subject)
    end

    def prometheus_alert_fired_email(project, user, alert)
      @project = project
      @alert = alert.present

      subject_text = "Alert: #{@alert.email_title}"
      mail(to: user.notification_email_for(@project.group), subject: subject(subject_text))
    end
  end
end

Emails::Projects.prepend_mod_with('Emails::Projects')
