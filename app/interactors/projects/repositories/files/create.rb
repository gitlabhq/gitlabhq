module Projects::Repositories::Files
  class Create < Projects::Repositories::Files::Base
    def perform
      project = context[:project]
      repository = project.repository

      params = context[:params]
      path = context[:path]
      ref = context[:ref]
      user = context[:user]

      file_name = File.basename(path)
      file_path = path

      unless file_name =~ Gitlab::Regex.path_regex
        msg = "Your changes could not be committed, because the file name " <<
              Gitlab::Regex.path_regex_message
        context.fail!(message: msg)
      end

      blob = repository.blob_at_branch(ref, file_path)

      if blob.present?
        msg = "Your changes could not be committed, because file with such name exists"
        context.fail!(message: msg)
      end

      oldrev = repository.find_branch(ref).target

      new_file_action = Gitlab::Satellite::NewFileAction.new(user, project,
                                                             ref, file_path)

      created_successfully = new_file_action.commit!(
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
