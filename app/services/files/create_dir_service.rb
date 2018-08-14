# frozen_string_literal: true

module Files
  class CreateDirService < Files::BaseService
    def create_commit!
      repository.create_dir(
        current_user,
        @file_path,
        message: @commit_message,
        branch_name: @branch_name,
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch)
    end
  end
end
