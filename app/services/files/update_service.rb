# frozen_string_literal: true

module Files
  class UpdateService < Files::BaseService
    def create_commit!
      transformer = Lfs::FileTransformer.new(project, repository, @branch_name, start_branch_name: @start_branch)

      result = transformer.new_file(@file_path, @file_content)

      create_transformed_commit(result.content)
    end

    def create_transformed_commit(content_or_lfs_pointer)
      repository.update_file(
        current_user,
        @file_path,
        content_or_lfs_pointer,
        message: @commit_message,
        branch_name: @branch_name,
        previous_path: @previous_path,
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch,
        execute_filemode: @execute_filemode
      )
    end

    private

    def validate!
      super

      if file_has_changed?(@file_path, @last_commit_sha)
        raise FileChangedError, _('You are attempting to update a file that has changed since you started editing it.')
      end
    end
  end
end
