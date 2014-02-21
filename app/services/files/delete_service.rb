require_relative "base_service"

module Files
  class DeleteService < BaseService
    def execute
      allowed = if project.protected_branch?(ref)
                  can?(current_user, :push_code_to_protected_branches, project)
                else
                  can?(current_user, :push_code, project)
                end

      unless allowed
        return error("You are not allowed to push into this branch")
      end

      unless repository.branch_names.include?(ref)
        return error("You can only create files if you are on top of a branch")
      end

      blob = repository.blob_at_branch(ref, path)

      unless blob
        return error("You can only edit text files")
      end

      delete_file_action = Gitlab::Satellite::DeleteFileAction.new(current_user, project, ref, path)

      deleted_successfully = delete_file_action.commit!(
        nil,
        params[:commit_message]
      )

      if deleted_successfully
        success
      else
        error("Your changes could not be committed, because the file has been changed")
      end
    end
  end
end
