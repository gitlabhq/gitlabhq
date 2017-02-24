module Files
  class CreateService < Files::BaseService
    def commit
      repository.create_file(
        current_user,
        @file_path,
        @file_content,
        message: @commit_message,
        branch_name: @target_branch,
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch)
    end

    def validate
      super

      if @file_content.nil?
        raise_error("You must provide content.")
      end

      if @file_path =~ Gitlab::Regex.directory_traversal_regex
        raise_error(
          'Your changes could not be committed, because the file name ' +
          Gitlab::Regex.directory_traversal_regex_message
        )
      end

      unless @file_path =~ Gitlab::Regex.file_path_regex
        raise_error(
          'Your changes could not be committed, because the file name ' +
          Gitlab::Regex.file_path_regex_message
        )
      end

      unless project.empty_repo?
        @file_path.slice!(0) if @file_path.start_with?('/')

        blob = repository.blob_at_branch(@start_branch, @file_path)

        if blob
          raise_error('Your changes could not be committed because a file with the same name already exists')
        end
      end
    end
  end
end
