module API
  # Internal access API
  class Internal < Grape::API
    namespace 'internal' do
      # Check if git command is allowed to project
      #
      # Params:
      #   key_id - ssh key id for Git over SSH
      #   user_id - user id for Git over HTTP
      #   project - project path with namespace
      #   action - git action (git-upload-pack or git-receive-pack)
      #   ref - branch name
      #   forced_push - forced_push
      #
      get "/allowed" do
        # Check for *.wiki repositories.
        # Strip out the .wiki from the pathname before finding the
        # project. This applies the correct project permissions to
        # the wiki repository as well.
        project_path = params[:project]
        project_path.gsub!(/\.wiki/,'') if project_path =~ /\.wiki/
        project = Project.find_with_namespace(project_path)
        return false unless project

        actor = if params[:key_id]
                  Key.find(params[:key_id])
                elsif params[:user_id]
                  User.find(params[:user_id])
                end

        return false unless actor

        Gitlab::GitAccess.new.allowed?(
          actor,
          params[:action],
          project,
          params[:ref],
          params[:oldrev],
          params[:newrev],
          params[:forced_push]
        )
      end

      #
      # Discover user by ssh key
      #
      get "/discover" do
        key = Key.find(params[:key_id])
        present key.user, with: Entities::UserSafe
      end

      get "/check" do
        {
          api_version: API.version,
          gitlab_version: Gitlab::VERSION,
          gitlab_rev: Gitlab::REVISION,
        }
      end
    end
  end
end
