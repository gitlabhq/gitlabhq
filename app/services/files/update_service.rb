require_relative "base_service"

module Files
  class UpdateService < BaseService
    def execute
      allowed = ::Gitlab::GitAccess.can_push_to_branch?(current_user, project, ref)

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

      edit_file_action = Gitlab::Satellite::EditFileAction.new(current_user, project, ref, path)
      edit_file_action.commit!(
        params[:content],
        params[:commit_message],
        params[:encoding],
        params[:new_branch]
      )

      success
    rescue Gitlab::Satellite::CheckoutFailed => ex
      error("Your changes could not be committed because ref '#{ref}' could not be checked out", 400)
    rescue Gitlab::Satellite::CommitFailed => ex
      error("Your changes could not be committed. Maybe there was nothing to commit?", 409)
    rescue Gitlab::Satellite::PushFailed => ex
      error("Your changes could not be committed. Maybe the file was changed by another process?", 409)
    end
  end
end
