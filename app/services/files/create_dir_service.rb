require_relative "base_service"

module Files
  class CreateDirService < Files::BaseService
    def commit
      repository.commit_dir(current_user, @file_path, @commit_message, @target_branch)
    end

    def validate
      super

      unless @file_path =~ Gitlab::Regex.file_path_regex
        raise_error(
          'Your changes could not be committed, because the file path ' +
          Gitlab::Regex.file_path_regex_message
        )
      end
    end
  end
end
