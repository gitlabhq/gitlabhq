require_relative "base_service"

module Files
  class DeleteService < BaseService
    def execute
      error = permission_check
      return error if error

      error = text_check
      return error if error

      delete_file_action = Gitlab::Satellite::DeleteFileAction.new(current_user, project, ref, path)
      deleted_successfully = delete_file_action.commit!(
        nil,
        params[:commit_message]
      )

      get_execute_output(deleted_successfully)
    end
  end
end
