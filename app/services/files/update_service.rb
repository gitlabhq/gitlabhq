require_relative "base_service"

module Files
  class UpdateService < Files::BaseService
    class FileChangedError < StandardError; end

    def commit
      repository.update_file(current_user, @file_path, @file_content,
                             branch: @target_branch,
                             previous_path: @previous_path,
                             message: @commit_message)
    end

    private

    def validate
      super

      if file_has_changed?
        raise FileChangedError.new("You are attempting to update a file that has changed since you started editing it.")
      end
    end

    def file_has_changed?
      return false unless @last_commit_sha && last_commit

      @last_commit_sha != last_commit.sha
    end

    def last_commit
      @last_commit ||= Gitlab::Git::Commit.
        last_for_path(@source_project.repository, @source_branch, @file_path)
    end
  end
end
