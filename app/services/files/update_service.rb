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
                             base_project: @base_project,
                             base_branch_name: @base_branch)
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
        last_for_path(@base_project.repository, @base_branch, @file_path)
    end
  end
end
