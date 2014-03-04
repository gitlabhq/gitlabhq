module API
  # Internal access API
  class Internal < Grape::API

    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }

    namespace 'internal' do
      #
      # Check if ssh key has access to project code
      #
      # Params:
      #   key_id - SSH Key id
      #   project - project path with namespace
      #   action - git action (git-upload-pack or git-receive-pack)
      #   ref - branch name
      #
      get "/allowed" do
        # Check for *.wiki repositories.
        # Strip out the .wiki from the pathname before finding the
        # project. This applies the correct project permissions to
        # the wiki repository as well.
        project_path = params[:project]
        project_path.gsub!(/\.wiki/,'') if project_path =~ /\.wiki/

        key = Key.find(params[:key_id])
        project = Project.find_with_namespace(project_path)
        git_cmd = params[:action]
        return false unless project


        if key.is_a? DeployKey
          key.projects.include?(project) && DOWNLOAD_COMMANDS.include?(git_cmd)
        else
          user = key.user

          return false if user.blocked?
          if Gitlab.config.ldap.enabled
            return false if user.ldap_user? && Gitlab::LDAP::User.blocked?(user.extern_uid)
          end

          action = case git_cmd
                   when *DOWNLOAD_COMMANDS
                     then :download_code
                   when *PUSH_COMMANDS
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

