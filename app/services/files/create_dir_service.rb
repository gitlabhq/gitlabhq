require_relative "base_service"

module Files
  class CreateDirService < Files::BaseService
    def commit
      repository.commit_dir(current_user, @file_path, @commit_message, @target_branch)
    end
  end
end
