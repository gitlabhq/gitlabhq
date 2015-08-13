require_relative "base_service"

module Files
  class UpdateService < Files::BaseService
    def commit
      CommitService.transaction(project, current_user, @target_branch)  do |tmp_ref|
        repository.commit_file(current_user, @file_path, @file_content, @commit_message, tmp_ref)
      end
    end
  end
end
