# frozen_string_literal: true

module Files
  class CreateService < Files::BaseService
    def create_commit!
      transformer = Lfs::FileTransformer.new(project, repository, @branch_name, start_branch_name: @start_branch)

      result = transformer.new_file(@file_path, @file_content)

      create_transformed_commit(result.content)
    end

    private

    def validate!
      super

      raise_error(_('You must provide a file path')) if @file_path.nil?
    end

    def create_transformed_commit(content_or_lfs_pointer)
      repository.create_file(
        current_user,
        @file_path,
        content_or_lfs_pointer,
        message: @commit_message,
        branch_name: @branch_name,
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch,
        execute_filemode: @execute_filemode)
    end
  end
end
