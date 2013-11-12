module Files
  class UpdateContext < BaseContext
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

      blob = repository.blob_at(ref, path)

      unless blob
        return error("You can only edit text files")
      end

      new_file_action = Gitlab::Satellite::EditFileAction.new(current_user, project, ref, path)
      created_successfully = new_file_action.commit!(
        params[:content],
        params[:commit_message]
      )

      if created_successfully
        success
      else
        error("Your changes could not be commited, because the file has been changed")
      end
    end
  end
end
