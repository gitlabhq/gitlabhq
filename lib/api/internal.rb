module API
  # Internal access API
  class Internal < Grape::API
    before { authenticate_by_gitlab_shell_token! }

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
      #   protocol - Git access protocol being used, e.g. HTTP or SSH
      #

      helpers do
        def wiki?
          @wiki ||= params[:project].end_with?('.wiki') &&
            !Project.find_with_namespace(params[:project])
        end

        def project
          @project ||= begin
            project_path = params[:project]

            # Check for *.wiki repositories.
            # Strip out the .wiki from the pathname before finding the
            # project. This applies the correct project permissions to
            # the wiki repository as well.
            project_path.chomp!('.wiki') if wiki?

            Project.find_with_namespace(project_path)
          end
        end
      end

      post "/allowed" do
        status 200

        actor =
          if params[:key_id]
            Key.find_by(id: params[:key_id])
          elsif params[:user_id]
            User.find_by(id: params[:user_id])
          end

        protocol = params[:protocol]

        access =
          if wiki?
            Gitlab::GitAccessWiki.new(actor, project, protocol)
          else
            Gitlab::GitAccess.new(actor, project, protocol)
          end

        access_status = access.check(params[:action], params[:changes])

        response = { status: access_status.status, message: access_status.message }

        if access_status.status
          # Return the repository full path so that gitlab-shell has it when
          # handling ssh commands
          response[:repository_path] =
            if wiki?
              project.wiki.repository.path_to_repo
            else
              project.repository.path_to_repo
            end
        end

        response
      end

      post "/lfs_authenticate" do
        status 200

        key = Key.find(params[:key_id])
        user = key.user

        token_handler =
          if user
            Gitlab::LfsToken.new(user)
          else
            Gitlab::LfsToken.new(key)
          end

        {
          username: token_handler.actor_name,
          lfs_token: token_handler.generate,
          repository_http_path: project.http_url_to_repo
        }
      end

      get "/merge_request_urls" do
        ::MergeRequests::GetUrlsService.new(project).execute(params[:changes])
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

      get "/broadcast_message" do
        if message = BroadcastMessage.current
          present message, with: Entities::BroadcastMessage
        else
          {}
        end
      end

      post '/two_factor_recovery_codes' do
        status 200

        key = Key.find_by(id: params[:key_id])

        unless key
          return { 'success' => false, 'message' => 'Could not find the given key' }
        end

        if key.is_a?(DeployKey)
          return { success: false, message: 'Deploy keys cannot be used to retrieve recovery codes' }
        end

        user = key.user

        unless user
          return { success: false, message: 'Could not find a user for the given key' }
        end

        unless user.two_factor_enabled?
          return { success: false, message: 'Two-factor authentication is not enabled for this user' }
        end

        codes = user.generate_otp_backup_codes!
        user.save!

        { success: true, recovery_codes: codes }
      end
    end
  end
end
