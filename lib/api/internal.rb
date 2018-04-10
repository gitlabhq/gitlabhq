module API
  # Internal access API
  class Internal < Grape::API
    before { authenticate_by_gitlab_shell_token! }

    helpers ::API::Helpers::InternalHelpers
    helpers ::Gitlab::Identifier

    namespace 'internal' do
      # Check if git command is allowed to project
      #
      # Params:
      #   key_id - ssh key id for Git over SSH
      #   user_id - user id for Git over HTTP
      #   protocol - Git access protocol being used, e.g. HTTP or SSH
      #   project - project full_path (not path on disk)
      #   action - git action (git-upload-pack or git-receive-pack)
      #   changes - changes as "oldrev newrev ref", see Gitlab::ChangesList
      post "/allowed" do
        status 200

        # Stores some Git-specific env thread-safely
        env = parse_env
        Gitlab::Git::HookEnv.set(gl_repository, env) if project

        actor =
          if params[:key_id]
            Key.find_by(id: params[:key_id])
          elsif params[:user_id]
            User.find_by(id: params[:user_id])
          end

        protocol = params[:protocol]

        actor.update_last_used_at if actor.is_a?(Key)
        user =
          if actor.is_a?(Key)
            actor.user
          else
            actor
          end

        access_checker_klass = wiki? ? Gitlab::GitAccessWiki : Gitlab::GitAccess
        access_checker = access_checker_klass.new(actor, project,
          protocol, authentication_abilities: ssh_authentication_abilities,
                    namespace_path: namespace_path, project_path: project_path,
                    redirected_path: redirected_path)

        begin
          access_checker.check(params[:action], params[:changes])
          @project ||= access_checker.project
        rescue Gitlab::GitAccess::UnauthorizedError, Gitlab::GitAccess::NotFoundError => e
          return { status: false, message: e.message }
        end

        log_user_activity(actor)

        {
          status: true,
          gl_repository: gl_repository,
          gl_username: user&.username,
          repository_path: repository_path,
          gitaly: gitaly_payload(params[:action])
        }
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
        merge_request_urls
      end

      #
      # Get a ssh key using the fingerprint
      #
      get "/authorized_keys" do
        fingerprint = params.fetch(:fingerprint) do
          Gitlab::InsecureKeyFingerprint.new(params.fetch(:key)).fingerprint
        end
        key = Key.find_by(fingerprint: fingerprint)
        not_found!("Key") if key.nil?
        present key, with: Entities::SSHKey
      end

      #
      # Discover user by ssh key or user id
      #
      get "/discover" do
        if params[:key_id]
          key = Key.find(params[:key_id])
          user = key.user
        elsif params[:user_id]
          user = User.find_by(id: params[:user_id])
        end

        present user, with: Entities::UserSafe
      end

      get "/check" do
        {
          api_version: API.version,
          gitlab_version: Gitlab::VERSION,
          gitlab_rev: Gitlab::REVISION,
          redis: redis_ping
        }
      end

      get "/broadcast_messages" do
        if messages = BroadcastMessage.current
          present messages, with: Entities::BroadcastMessage
        else
          []
        end
      end

      get "/broadcast_message" do
        if message = BroadcastMessage.current&.last
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

        codes = nil

        ::Users::UpdateService.new(current_user, user: user).execute! do |user|
          codes = user.generate_otp_backup_codes!
        end

        { success: true, recovery_codes: codes }
      end

      post '/pre_receive' do
        status 200

        reference_counter_increased = Gitlab::ReferenceCounter.new(params[:gl_repository]).increase

        { reference_counter_increased: reference_counter_increased }
      end

      post "/notify_post_receive" do
        status 200

        # TODO: Re-enable when Gitaly is processing the post-receive notification
        # return unless Gitlab::GitalyClient.enabled?
        #
        # begin
        #   repository = wiki? ? project.wiki.repository : project.repository
        #   Gitlab::GitalyClient::NotificationService.new(repository.raw_repository).post_receive
        # rescue GRPC::Unavailable => e
        #   render_api_error!(e, 500)
        # end
      end

      post '/post_receive' do
        status 200
        PostReceive.perform_async(params[:gl_repository], params[:identifier],
          params[:changes])
        broadcast_message = BroadcastMessage.current&.last&.message
        reference_counter_decreased = Gitlab::ReferenceCounter.new(params[:gl_repository]).decrease

        output = {
          merge_request_urls: merge_request_urls,
          broadcast_message: broadcast_message,
          reference_counter_decreased: reference_counter_decreased
        }

        project = Gitlab::GlRepository.parse(params[:gl_repository]).first
        user = identify(params[:identifier])

        # A user is not guaranteed to be returned; an orphaned write deploy
        # key could be used
        if user
          redirect_message = Gitlab::Checks::ProjectMoved.fetch_message(user.id, project.id)
          project_created_message = Gitlab::Checks::ProjectCreated.fetch_message(user.id, project.id)

          output[:redirected_message] = redirect_message if redirect_message
          output[:project_created_message] = project_created_message if project_created_message
        end

        output
      end
    end
  end
end
