module Projects::Repositories::Files
  class Delete < Projects::Repositories::Files::Base
    def perform
      project = context[:project]
      repository = project.repository

      params = context[:params]
      path = context[:path]
      ref = context[:ref]
      user = context[:user]

      file_path = path

      blob = repository.blob_at_branch(ref, file_path)

      unless blob
        context.fail!(message: 'You can edit only text files')
      end

      oldrev = repository.find_branch(ref).target

      delete_file_action = Gitlab::Satellite::DeleteFileAction.new(user, project,
                                                                   ref, path)

      deleted_successfully = delete_file_action.commit!(
        nil,
        params[:commit_message]
      )

      if deleted_successfully
        context[:oldrev] = oldrev
        context[:newrev] = repository.find_branch(ref).target
      else
        context.fail!(message: "Your changes could not be committed, because the file has been changed")
      end
    end

    def rollback
      # Return file (Reset commit)
    end
  end
end
