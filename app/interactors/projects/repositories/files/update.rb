module Projects::Repositories::Files
  class Create < Projects::Repositories::Files::Base
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

      edit_file_action = Gitlab::Satellite::EditFileAction.new(user, project,
                                                               ref, path)
      created_successfully = edit_file_action.commit!(
        params[:content],
        params[:commit_message],
        params[:encoding]
      )

      if created_successfully
        context[:oldrev] = oldrev
        context[:newrev] = repository.find_branch(ref).target
      else
        context.fail!(message: "Your changes could not be committed, because the file has been changed")
      end
    end

    def rollback
      # Remove file
    end
  end
end
