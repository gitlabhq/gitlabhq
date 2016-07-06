require_relative "base_service"

module Files
  class UpdateService < Files::BaseService
    def commit
      repository.update_file(current_user, @file_path, @file_content,
                             branch: @target_branch,
                             previous_path: @previous_path,
                             message: @commit_message)
    end
  end
end
