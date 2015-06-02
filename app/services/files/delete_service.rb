require_relative "base_service"

module Files
  class DeleteService < Files::BaseService
    def execute
      allowed = ::Gitlab::GitAccess.new(current_user, project).can_push_to_branch?(ref)

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

      sha = repository.remove_file(
        current_user,
        path,
        params[:commit_message],
        ref
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
