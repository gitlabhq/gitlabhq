module Gitlab
  # Access API
  class Internal < Grape::API

    get "/allowed" do
      user = User.find_by_username(params[:username])
      project = Project.find_with_namespace(params[:project])
      action = case params[:action]
               when 'git-upload-pack'
                 then :download_code
               when 'git-receive-pack'
                 then
                 if project.protected_branch?(params[:ref])
                   :push_code_to_protected_branches
                 else
                   :push_code
                 end
               end

      user.can?(action, project)
    end
  end
end

