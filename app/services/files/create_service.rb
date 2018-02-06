module Files
  class CreateService < Files::BaseService
    def create_commit!
      handler = Lfs::FileModificationHandler.new(project, @branch_name)

      handler.new_file(@file_path, @file_content) do |content_or_lfs_pointer|
        create_transformed_commit(content_or_lfs_pointer)
      end
    end

    private

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
        start_branch_name: @start_branch)
    end
  end
end
