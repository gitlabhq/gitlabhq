require_relative "base_service"

module Files
  class DeleteService < Files::BaseService
    def commit
      CommitService.transaction(project, current_user, @target_branch)  do |tmp_ref|
        repository.remove_file(current_user, @file_path, @commit_message, tmp_ref)
      end
    end
  end
end
