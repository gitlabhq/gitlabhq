require_relative "base_service"

module Files
  class UpdateService < Files::BaseService
    def commit

      repository.update_file(current_user, @file_path, @previous_path, @file_content, @commit_message, @target_branch, true)
    end
  end
end
