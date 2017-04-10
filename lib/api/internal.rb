module API
  # Internal access API
  class Internal < Grape::API
    before { authenticate_by_gitlab_shell_token! }

    helpers ::API::Helpers::InternalHelpers

    namespace 'internal' do
      # Check if git command is allowed to project
      #
      # Params:
      #   key_id - ssh key id for Git over SSH
      #   user_id - user id for Git over HTTP
      #   protocol - Git access protocol being used, e.g. HTTP or SSH
      #   project - project path with namespace
      #   action - git action (git-upload-pack or git-receive-pack)
      #   changes - changes as "oldrev newrev ref", see Gitlab::ChangesList
      post "/allowed" do
        status 200

        # Stores some Git-specific env thread-safely
        Gitlab::Git::Env.set(parse_env)

        actor =
          if params[:key_id]
            Key.find_by(id: params[:key_id])
          elsif params[:user_id]
            User.find_by(id: params[:user_id])
          end

        protocol = params[:protocol]

        actor.update_last_used_at if actor.is_a?(Key)

        access_checker = wiki? ? Gitlab::GitAccessWiki : Gitlab::GitAccess
        access_status = access_checker
          .new(actor, project, protocol, authentication_abilities: ssh_authentication_abilities)
          .check(params[:action], params[:changes])

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
        key.update_last_used_at

        token_handler = Gitlab::LfsToken.new(key)

        {
          username: token_handler.actor_name,
          lfs_token: token_handler.token,
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

        if key
          key.update_last_used_at
        else
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

      post "/notify_post_receive" do
        status 200

        return unless Gitlab::GitalyClient.enabled?

        relative_path = Gitlab::RepoPath.strip_storage_path(params[:repo_path])
        project = Project.find_by_full_path(relative_path.sub(/\.(git|wiki)\z/, ''))

        begin
          Gitlab::GitalyClient::Notifications.new(project.repository).post_receive
        rescue GRPC::Unavailable => e
          render_api_error(e, 500)
        end
      end
    end
  end
end
