require_relative "base_service"

module Files
  class CreateService < BaseService
    def execute
      error = permission_check
      return error if error

      unless File.basename(path) =~ Gitlab::Regex.path_regex
        return error(
          'Your changes could not be committed, because the file name ' +
          Gitlab::Regex.path_regex_message
        )
      end

      if blob
        return error("Your changes could not be committed, because file with such name exists")
      end

      new_file_action = Gitlab::Satellite::NewFileAction.
        new(current_user, project, ref, path)
      created_successfully = new_file_action.commit!(
        params[:content],
        params[:commit_message],
        params[:encoding]
      )

      if created_successfully
        success
      else
        error("Your changes could not be committed, because the file has been changed")
      end
    end
  end
end
