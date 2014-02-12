module Emails
  module Projects
    def project_access_granted_email(user_project_id)
      @users_project = UsersProject.find user_project_id
      @project = @users_project.project
      mail(to: @users_project.user.email,
           subject: subject("Access to project was granted"))
    end

    def project_was_moved_email(project_id, user_id)
      @user = User.find user_id
      @project = Project.find project_id
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

      mail(to: recipient, subject: subject("New push to repository"))
    end
  end
end
