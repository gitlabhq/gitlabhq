module Files
  class UpdateService < Files::BaseService
    class FileChangedError < StandardError; end

    def commit
      repository.update_file(current_user, @file_path, @file_content,
                             message: @commit_message,
                             branch_name: @target_branch,
                             previous_path: @previous_path,
                             author_email: @author_email,
                             author_name: @author_name,
                             start_project: @start_project,
                             start_branch_name: @start_branch)
    end

    private

    def validate
      super

      if file_has_changed?
        raise FileChangedError.new("You are attempting to update a file that has changed since you started editing it.")
      end
    end

    def last_commit
      @last_commit ||= Gitlab::Git::Commit.
        last_for_path(@start_project.repository, @start_branch, @file_path)
    end
  end
end
