module Emails
  module Projects
    def project_access_granted_email(project_member_id)
      @project_member = ProjectMember.find project_member_id
      @project = @project_member.project

      @target_url = namespace_project_url(@project.namespace, @project)
      @current_user = @project_member.user

      mail(to: @project_member.user.notification_email,
           subject: subject("Access to project was granted"))
    end

    def project_member_invited_email(project_member_id, token)
      @project_member = ProjectMember.find project_member_id
      @project = @project_member.project
      @token = token

      @target_url = namespace_project_url(@project.namespace, @project)
      @current_user = @project_member.user

      mail(to: @project_member.invite_email,
           subject: "Invitation to join project #{@project.name_with_namespace}")
    end

    def project_invite_accepted_email(project_member_id)
      @project_member = ProjectMember.find project_member_id
      return if @project_member.created_by.nil?

      @project = @project_member.project

      @target_url = namespace_project_url(@project.namespace, @project)
      @current_user = @project_member.created_by

      mail(to: @project_member.created_by.notification_email,
           subject: subject("Invitation accepted"))
    end

    def project_invite_declined_email(project_id, invite_email, access_level, created_by_id)
      return if created_by_id.nil?

      @project = Project.find(project_id)
      @current_user = @created_by = User.find(created_by_id)
      @access_level = access_level
      @invite_email = invite_email

      @target_url = namespace_project_url(@project.namespace, @project)

      mail(to: @created_by.notification_email,
           subject: subject("Invitation declined"))
    end

    def project_was_moved_email(project_id, user_id, old_path_with_namespace)
      @current_user = @user = User.find user_id
      @project = Project.find project_id
      @target_url = namespace_project_url(@project.namespace, @project)
      @old_path_with_namespace = old_path_with_namespace
      mail(to: @user.notification_email,
           subject: subject("Project was moved"))
    end

    def repository_push_email(project_id, recipient, opts = {})
      @message =
        Gitlab::Email::Message::RepositoryPush.new(self, project_id, recipient, opts)

      # used in notify layout
      @target_url = @message.target_url
      @project = Project.find project_id

      add_project_headers
      headers['X-GitLab-Author'] = @message.author_username

      mail(from:      sender(@message.author_id, @message.send_from_committer_email?),
           reply_to:  @message.reply_to,
           to:        @message.recipient,
           subject:   @message.subject)
    end
  end
end
