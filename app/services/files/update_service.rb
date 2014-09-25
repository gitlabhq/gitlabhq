require_relative "base_service"

module Files
  class UpdateService < BaseService
    def execute
      error = permission_check
      return error if error

      error = text_check
      return error if error

      edit_file_action = Gitlab::Satellite::EditFileAction.new(current_user, project, ref, path)
      edited_successfully = edit_file_action.commit!(
        params[:content],
        params[:commit_message],
        params[:encoding]
      )

      get_execute_output(edited_successfully,
                         ' or there was nothing to commit?')
    end
  end
end
