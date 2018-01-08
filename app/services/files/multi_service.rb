module Files
  class MultiService < Files::BaseService
    UPDATE_FILE_ACTIONS = %w(update move delete).freeze

    def create_commit!
      repository.multi_action(
        current_user,
        message: @commit_message,
        branch_name: @branch_name,
        actions: params[:actions],
        author_email: @author_email,
        author_name: @author_name,
        start_project: @start_project,
        start_branch_name: @start_branch
      )
    rescue ArgumentError => e
      raise_error(e)
    end

    private

    def validate!
      super

      params[:actions].each { |action| validate_file_status!(action) }
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
