module Files
  class CreateService < Files::BaseService
    def create_commit!
      Lfs::FileTransformer.link_lfs_objects(project, @branch_name) do |transformer|
        content_or_lfs_pointer = transformer.new_file(@file_path, @file_content)
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
