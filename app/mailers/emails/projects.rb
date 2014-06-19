module Emails
  module Projects
    def project_access_granted_email(user_project_id)
      @users_project = UsersProject.find user_project_id
      @project = @users_project.project
      @target_url = project_url(@project)
      mail(to: @users_project.user.email,
           subject: subject("Access to project was granted"))
    end

    def project_was_moved_email(project_id, user_id)
      @user = User.find user_id
      @project = Project.find project_id
      @target_url = project_url(@project)
      mail(to: @user.email,
           subject: subject("Project was moved"))
    end

    def repository_push_email(project_id, recipient, author_id, branch, compare)
      @project = Project.find(project_id)
      @author  = User.find(author_id)
      @compare = compare
      @commits = Commit.decorate(compare.commits)
      @diffs   = compare.diffs
      @branch  = branch
      if @commits.length > 1
        @target_url = project_compare_url(@project, from: @commits.first, to: @commits.last)
        @subject = "#{@commits.length} new commits pushed to repository"
      else
        @target_url = project_commit_url(@project, @commits.first)
        @subject = @commits.first.title
      end

      mail(from: sender(author_id),
           to: recipient,
           subject: subject(@subject))
    end
  end
end
