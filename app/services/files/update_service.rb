module Files
  class UpdateService < Files::BaseService
    FileChangedError = Class.new(StandardError)

    def initialize(*args)
      super

      @last_commit_sha = params[:last_commit_sha]
    end

    def create_commit!
      repository.update_file(current_user, @file_path, @file_content,
                             message: @commit_message,
                             branch_name: @branch_name,
                             previous_path: @previous_path,
                             author_email: @author_email,
                             author_name: @author_name,
                             start_project: @start_project,
                             start_branch_name: @start_branch)
    end

    private

    def file_has_changed?
      return false unless @last_commit_sha && last_commit

      @last_commit_sha != last_commit.sha
    end

    def last_commit
      @last_commit ||= Gitlab::Git::Commit.
        last_for_path(@start_project.repository, @start_branch, @file_path)
    end

    def validate!
      super

      if file_has_changed?
        raise FileChangedError, "You are attempting to update a file that has changed since you started editing it."
      end
    end
  end
end
