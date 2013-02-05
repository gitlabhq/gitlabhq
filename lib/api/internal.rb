module Gitlab
  # Internal access API
  class Internal < Grape::API
    namespace 'internal' do
      #
      # Check if ssh key has access to project code
      #
      get "/allowed" do
        key = Key.find(params[:key_id])
        user = key.user

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

      #
      # Discover user by ssh key
      #
      get "/discover" do
        key = Key.find(params[:key_id])
        present key.user, with: Entities::User
      end

      get "/check" do
        {
          api_version: '3'
        }
      end
    end
  end
end

