module Emails
  module Projects
    prepend Emails::EE::Projects

    def project_was_moved_email(project_id, user_id, old_path_with_namespace)
      @current_user = @user = User.find user_id
      @project = Project.find project_id
      @target_url = project_url(@project)
      @old_path_with_namespace = old_path_with_namespace
      mail(to: @user.notification_email,
           subject: subject("Project was moved"))
    end

    def project_was_exported_email(current_user, project)
      @project = project
      mail(to: current_user.notification_email,
           subject: subject("Project was exported"))
    end

    def project_was_not_exported_email(current_user, project, errors)
      @project = project
      @errors = errors
      mail(to: current_user.notification_email,
           subject: subject("Project export error"))
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

      mail(from:      sender(@message.author_id, @message.send_from_committer_email?),
           reply_to:  @message.reply_to,
           subject:   @message.subject)
    end
  end
end
