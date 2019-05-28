# frozen_string_literal: true

module Files
  class DeleteService < Files::BaseService
    def create_commit!
      repository.delete_file(
        current_user,
        @file_path,
        message: @commit_message,
        branch_name: @branch_name,
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch)
    end

    private

    def validate!
      super

      if file_has_changed?(@file_path, @last_commit_sha)
        raise FileChangedError, _("You are attempting to delete a file that has been previously updated.")
      end
    end
  end
end
