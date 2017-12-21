module Files
  class MultiService < Files::BaseService
    UPDATE_FILE_ACTIONS = %w(update move delete).freeze

    def create_commit!
      repository.multi_action(
        user: current_user,
        message: @commit_message,
        branch_name: @branch_name,
        actions: params[:actions],
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch
      )
    end

    private

    def validate!
      super

      params[:actions].each do |action|
        validate_action!(action)
        validate_file_status!(action)
      end
    end

    def validate_action!(action)
      unless Gitlab::Git::Index::ACTIONS.include?(action[:action].to_s)
        raise_error("Unknown action '#{action[:action]}'")
      end
    end

    def validate_file_status!(action)
      return unless UPDATE_FILE_ACTIONS.include?(action[:action])

      file_path = action[:previous_path] || action[:file_path]

      if file_has_changed?(file_path, action[:last_commit_id])
        raise_error("The file has changed since you started editing it: #{file_path}")
      end
    end
  end
end
