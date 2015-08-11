require_relative "base_service"

module Files
  class CreateService < Files::BaseService
    def execute
      allowed = Gitlab::GitAccess.new(current_user, project).can_push_to_branch?(ref)

      unless allowed
        return error("You are not allowed to create file in this branch")
      end

      file_name = File.basename(path)
      file_path = path

      unless file_name =~ Gitlab::Regex.file_name_regex
        return error(
          'Your changes could not be committed, because the file name ' +
          Gitlab::Regex.file_name_regex_message
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

      content =
        if params[:encoding] == 'base64'
          Base64.decode64(params[:content])
        else
          params[:content]
        end

      sha = repository.commit_file(
        current_user,
        file_path,
        content,
        params[:commit_message],
        params[:new_branch] || ref
      )


      if sha
        after_commit(sha)
        success
      else
        error("Your changes could not be committed, because the file has been changed")
      end
    end
  end
end
