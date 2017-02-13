module Files
  class DestroyService < Files::BaseService
    def commit
      repository.remove_file(
        current_user,
        @file_path,
        message: @commit_message,
        branch_name: @target_branch,
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch)
    end
  end
end
