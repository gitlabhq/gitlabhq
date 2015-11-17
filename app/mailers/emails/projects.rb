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
      email = Gitlab::Email::RepositoryPush.new(project_id, recipient, opts)

      @project = email.project
      @current_user = @author  = email.author
      @reverse_compare = email.reverse_compare
      @compare = email.compare
      @ref_name  = email.ref_name
      @ref_type  = email.ref_type
      @action  = email.action
      @disable_diffs = email.disable_diffs
      @commits = email.commits
      @diffs = email.diffs
      @action_name = email.action_name
      @target_url = email.target_url
      @disable_footer = true

      mail(from:      sender(email.author_id, email.send_from_committer_email),
           reply_to:  email.reply_to,
           to:        email.recipient,
           subject:   email.subject)
    end
  end
end
