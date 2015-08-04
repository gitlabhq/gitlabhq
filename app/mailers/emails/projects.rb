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

    def project_was_moved_email(project_id, user_id)
      @current_user = @user = User.find user_id
      @project = Project.find project_id
      @target_url = namespace_project_url(@project.namespace, @project)
      mail(to: @user.notification_email,
           subject: subject("Project was moved"))
    end

    def repository_push_email(project_id, recipient,  author_id: nil, 
                                                      ref: nil, 
                                                      action: nil, 
                                                      compare: nil, 
                                                      reverse_compare: false, 
                                                      send_from_committer_email: false, 
                                                      disable_diffs: false)
      unless author_id && ref && action
        raise ArgumentError, "missing keywords: author_id, ref, action"
      end

      @project = Project.find(project_id)
      @current_user = @author  = User.find(author_id)
      @reverse_compare = reverse_compare
      @compare = compare
      @ref_name  = Gitlab::Git.ref_name(ref)
      @ref_type  = Gitlab::Git.tag_ref?(ref) ? "tag" : "branch"
      @action  = action
      @disable_diffs = disable_diffs

      if @compare
        @commits = Commit.decorate(compare.commits, @project)
        @diffs   = compare.diffs
      end

      @action_name = 
        case action
        when :create
          "pushed new"
        when :delete
          "deleted"
        else
          "pushed to"
        end

      @subject = "[Git]"
      @subject << "[#{@project.path_with_namespace}]"
      @subject << "[#{@ref_name}]" if action == :push
      @subject << " "

      if action == :push
        if @commits.length > 1
          @target_url = namespace_project_compare_url(@project.namespace,
                                                      @project,
                                                      from: Commit.new(@compare.base, @project),
                                                      to:   Commit.new(@compare.head, @project))
          @subject << "Deleted " if @reverse_compare
          @subject << "#{@commits.length} commits: #{@commits.first.title}"
        else
          @target_url = namespace_project_commit_url(@project.namespace,
                                                     @project, @commits.first)

          @subject << "Deleted 1 commit: " if @reverse_compare
          @subject << @commits.first.title
        end
      else
        unless action == :delete
          @target_url = namespace_project_tree_url(@project.namespace,
                                                   @project, @ref_name)
        end

        subject_action = @action_name.dup
        subject_action[0] = subject_action[0].capitalize
        @subject << "#{subject_action} #{@ref_type} #{@ref_name}"
      end

      @disable_footer = true

      reply_to = 
        if send_from_committer_email && can_send_from_user_email?(@author)
          @author.email
        else
          Gitlab.config.gitlab.email_reply_to
        end

      mail(from:      sender(author_id, send_from_committer_email),
           reply_to:  reply_to,
           to:        recipient,
           subject:   @subject)
    end
  end
end
