require_relative "base_service"

module Files
  class CreateService < BaseService
    def execute
      allowed = if project.protected_branch?(ref)
                  can?(current_user, :push_code_to_protected_branches, project)
                else
                  can?(current_user, :push_code, project)
                end

      unless allowed
        return error("You are not allowed to create file in this branch")
      end

      unless repository.branch_names.include?(ref)
        return error("You can only create files if you are on top of a branch")
      end

      file_name = File.basename(path)
      file_path = path

      unless file_name =~ Gitlab::Regex.path_regex
        return error("Your changes could not be committed, because file name contains not allowed characters")
      end

      blob = repository.blob_at_branch(ref, file_path)

      if blob
        return error("Your changes could not be committed, because file with such name exists")
      end

      new_file_action = Gitlab::Satellite::NewFileAction.new(current_user, project, ref, file_path)
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
