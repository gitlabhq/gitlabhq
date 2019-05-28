# frozen_string_literal: true

module Files
  class UpdateService < Files::BaseService
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

    def validate!
      super

      if file_has_changed?(@file_path, @last_commit_sha)
        raise FileChangedError, _('You are attempting to update a file that has changed since you started editing it.')
      end
    end
  end
end
