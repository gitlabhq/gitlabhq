module Emails
  module Projects
    def project_access_granted_email(user_project_id)
      @project_member = ProjectMember.find user_project_id
      @project = @project_member.project
      @target_url = namespace_project_url(@project.namespace, @project)
      mail(to: @project_member.user.email,
           subject: subject("Access to project was granted"))
    end

    def project_was_moved_email(project_id, user_id)
      @user = User.find user_id
      @project = Project.find project_id
      @target_url = namespace_project_url(@project.namespace, @project)
      mail(to: @user.notification_email,
           subject: subject("Project was moved"))
    end

    def repository_push_email(project_id, recipient, author_id, branch, compare, reverse_compare = false, send_from_committer_email = false, disable_diffs = false)
      @project = Project.find(project_id)
      @author  = User.find(author_id)
      @reverse_compare = reverse_compare
      @compare = compare
      @commits = Commit.decorate(compare.commits)
      @diffs   = compare.diffs
      @branch  = Gitlab::Git.ref_name(branch)
      @disable_diffs = disable_diffs

      @subject = "[#{@project.path_with_namespace}][#{@branch}] "

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

      @disable_footer = true

      mail(from: sender(author_id, send_from_committer_email),
           to: recipient,
           subject: @subject)
    end
  end
end
