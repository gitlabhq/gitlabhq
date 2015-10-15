require_relative "base_service"

module Files
  class UpdateService < Files::BaseService
    def commit
      repository.commit_file(current_user, @file_path, @file_content, @commit_message, @target_branch, true)
    end
  end
end
