module Emails
  module Projects
    def project_access_granted_email(user_project_id)
      @project_member = ProjectMember.find user_project_id
      @project = @project_member.project
      @target_url = namespace_project_url(@project.namespace, @project)
      @current_user = @project_member.user
      mail(to: @project_member.user.email,
           subject: subject("Access to project was granted"))
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
        @commits = Commit.decorate(compare.commits)
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

      @subject = "[#{@project.path_with_namespace}]"
      @subject << "[#{@ref_name}]" if action == :push
      @subject << " "

      if action == :push
        if @commits.length > 1
          @target_url = namespace_project_compare_url(@project.namespace,
                                                      @project,
                                                      from: Commit.new(@compare.base),
                                                      to:   Commit.new(@compare.head))
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

      mail(from: sender(author_id, send_from_committer_email),
           to: recipient,
           subject: @subject)
    end
  end
end
