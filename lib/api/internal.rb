# frozen_string_literal: true

module API
  # Internal access API
  class Internal < Grape::API
    before { authenticate_by_gitlab_shell_token! }

    helpers ::API::Helpers::InternalHelpers
    helpers ::Gitlab::Identifier

    UNKNOWN_CHECK_RESULT_ERROR = 'Unknown check result'.freeze

    helpers do
      def response_with_status(code: 200, success: true, message: nil, **extra_options)
        status code
        { status: success, message: message }.merge(extra_options).compact
      end

      def lfs_authentication_url(project)
        # This is a separate method so that EE can alter its behaviour more
        # easily.
        project.http_url_to_repo
      end
    end

    namespace 'internal' do
      # Check if git command is allowed for project
      #
      # Params:
      #   key_id - ssh key id for Git over SSH
      #   user_id - user id for Git over HTTP or over SSH in keyless SSH CERT mode
      #   username - user name for Git over SSH in keyless SSH cert mode
      #   protocol - Git access protocol being used, e.g. HTTP or SSH
      #   project - project full_path (not path on disk)
      #   action - git action (git-upload-pack or git-receive-pack)
      #   changes - changes as "oldrev newrev ref", see Gitlab::ChangesList
      # rubocop: disable CodeReuse/ActiveRecord
      post "/allowed" do
        # Stores some Git-specific env thread-safely
        env = parse_env
        Gitlab::Git::HookEnv.set(gl_repository, env) if project

        actor =
          if params[:key_id]
            Key.find_by(id: params[:key_id])
          elsif params[:user_id]
            User.find_by(id: params[:user_id])
          elsif params[:username]
            UserFinder.new(params[:username]).find_by_username
          end

        protocol = params[:protocol]

        actor.update_last_used_at if actor.is_a?(Key)
        user =
          if actor.is_a?(Key)
            actor.user
          else
            actor
          end

        access_checker_klass = repo_type.access_checker_class
        access_checker = access_checker_klass.new(actor, project,
          protocol, authentication_abilities: ssh_authentication_abilities,
                    namespace_path: namespace_path, project_path: project_path,
                    redirected_path: redirected_path)

        check_result = begin
                         result = access_checker.check(params[:action], params[:changes])
                         @project ||= access_checker.project
                         result
                       rescue Gitlab::GitAccess::UnauthorizedError => e
                         break response_with_status(code: 401, success: false, message: e.message)
                       rescue Gitlab::GitAccess::TimeoutError => e
                         break response_with_status(code: 503, success: false, message: e.message)
                       rescue Gitlab::GitAccess::NotFoundError => e
                         break response_with_status(code: 404, success: false, message: e.message)
                       end

        log_user_activity(actor)

        case check_result
        when ::Gitlab::GitAccessResult::Success
          payload = {
            gl_repository: gl_repository,
            gl_project_path: gl_project_path,
            gl_id: Gitlab::GlId.gl_id(user),
            gl_username: user&.username,
            git_config_options: [],
            gitaly: gitaly_payload(params[:action]),
            gl_console_messages: check_result.console_messages
          }

          # Custom option for git-receive-pack command
          receive_max_input_size = Gitlab::CurrentSettings.receive_max_input_size.to_i
          if receive_max_input_size > 0
            payload[:git_config_options] << "receive.maxInputSize=#{receive_max_input_size.megabytes}"
          end

          response_with_status(**payload)
        when ::Gitlab::GitAccessResult::CustomAction
          response_with_status(code: 300, message: check_result.message, payload: check_result.payload)
        else
          response_with_status(code: 500, success: false, message: UNKNOWN_CHECK_RESULT_ERROR)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      post "/lfs_authenticate" do
        status 200

        if params[:key_id]
          actor = Key.find(params[:key_id])
          actor.update_last_used_at
        elsif params[:user_id]
          actor = User.find_by(id: params[:user_id])
          raise ActiveRecord::RecordNotFound.new("No such user id!") unless actor
        else
          raise ActiveRecord::RecordNotFound.new("No key_id or user_id passed!")
        end

        Gitlab::LfsToken
          .new(actor)
          .authentication_payload(lfs_authentication_url(project))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      get "/merge_request_urls" do
        merge_request_urls
      end

      #
      # Get a ssh key using the fingerprint
      #
      # rubocop: disable CodeReuse/ActiveRecord
      get "/authorized_keys" do
        fingerprint = params.fetch(:fingerprint) do
          Gitlab::InsecureKeyFingerprint.new(params.fetch(:key)).fingerprint
        end
        key = Key.find_by(fingerprint: fingerprint)
        not_found!("Key") if key.nil?
        present key, with: Entities::SSHKey
      end
      # rubocop: enable CodeReuse/ActiveRecord

      #
      # Discover user by ssh key, user id or username
      #
      # rubocop: disable CodeReuse/ActiveRecord
      get "/discover" do
        if params[:key_id]
          key = Key.find(params[:key_id])
          user = key.user
        elsif params[:user_id]
          user = User.find_by(id: params[:user_id])
        elsif params[:username]
          user = UserFinder.new(params[:username]).find_by_username
        end

        present user, with: Entities::UserSafe
      end
      # rubocop: enable CodeReuse/ActiveRecord

      get "/check" do
        {
          api_version: API.version,
          gitlab_version: Gitlab::VERSION,
          gitlab_rev: Gitlab.revision,
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

      # rubocop: disable CodeReuse/ActiveRecord
      post '/two_factor_recovery_codes' do
        status 200

        if params[:key_id]
          key = Key.find_by(id: params[:key_id])

          if key
            key.update_last_used_at
          else
            break { 'success' => false, 'message' => 'Could not find the given key' }
          end

          if key.is_a?(DeployKey)
            break { success: false, message: 'Deploy keys cannot be used to retrieve recovery codes' }
          end

          user = key.user

          unless user
            break { success: false, message: 'Could not find a user for the given key' }
          end
        elsif params[:user_id]
          user = User.find_by(id: params[:user_id])

          unless user
            break { success: false, message: 'Could not find the given user' }
          end
        end

        unless user.two_factor_enabled?
          break { success: false, message: 'Two-factor authentication is not enabled for this user' }
        end

        codes = nil

        ::Users::UpdateService.new(current_user, user: user).execute! do |user|
          codes = user.generate_otp_backup_codes!
        end

        { success: true, recovery_codes: codes }
      end
      # rubocop: enable CodeReuse/ActiveRecord

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

        response = Gitlab::InternalPostReceive::Response.new
        user = identify(params[:identifier])
        project = Gitlab::GlRepository.parse(params[:gl_repository]).first
        push_options = Gitlab::PushOptions.new(params[:push_options])

        response.reference_counter_decreased = Gitlab::ReferenceCounter.new(params[:gl_repository]).decrease

        PostReceive.perform_async(params[:gl_repository], params[:identifier],
          params[:changes], push_options.as_json)

        mr_options = push_options.get(:merge_request)
        if mr_options.present?
          message = process_mr_push_options(mr_options, project, user, params[:changes])
          response.add_alert_message(message)
        end

        broadcast_message = BroadcastMessage.current&.last&.message
        response.add_alert_message(broadcast_message)

        response.add_merge_request_urls(merge_request_urls)

        # A user is not guaranteed to be returned; an orphaned write deploy
        # key could be used
        if user
          redirect_message = Gitlab::Checks::ProjectMoved.fetch_message(user.id, project.id)
          project_created_message = Gitlab::Checks::ProjectCreated.fetch_message(user.id, project.id)

          response.add_basic_message(redirect_message)
          response.add_basic_message(project_created_message)
        end

        present response, with: Entities::InternalPostReceive::Response
      end
    end
  end
end
