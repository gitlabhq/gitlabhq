module Files
  class DeleteService < Files::BaseService
    def commit
      repository.remove_file(
        current_user,
        @file_path,
        message: @commit_message,
        branch_name: @target_branch,
        author_email: @author_email,
        author_name: @author_name,
        base_project: @base_project,
        base_branch_name: @base_branch)
    end
  end
end
