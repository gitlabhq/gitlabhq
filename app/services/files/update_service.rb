require_relative "base_service"

module Files
  class UpdateService < Files::BaseService
    def commit
      # Need to update file_path with the new filename
      repository.commit_file(current_user, @file_path, @file_content, @commit_message, @target_branch, true)
    end
  end
end
