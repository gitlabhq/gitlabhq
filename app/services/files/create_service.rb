require_relative "base_service"

module Files
  class CreateService < BaseService
    def execute
      allowed = Gitlab::GitAccess.can_push_to_branch?(current_user, project, ref)

      unless allowed
        return error("You are not allowed to create file in this branch")
      end

      if git_hook && !git_hook.commit_message_allowed?(params[:commit_message])
        return error("Commit message must match next format: #{git_hook.commit_message_regex}")
      end

      file_name = File.basename(path)
      file_path = path

      unless file_name =~ Gitlab::Regex.path_regex
        return error(
          'Your changes could not be committed, because the file name ' +
          Gitlab::Regex.path_regex_message
        )
      end

      if project.empty_repo?
        # everything is ok because repo does not have a commits yet
      else
        unless repository.branch_names.include?(ref)
          return error("You can only create files if you are on top of a branch")
        end

        blob = repository.blob_at_branch(ref, file_path)

        if blob
          return error("Your changes could not be committed, because file with such name exists")
        end
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
