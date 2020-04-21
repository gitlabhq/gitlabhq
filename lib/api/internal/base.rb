# frozen_string_literal: true

module API
  # Internal access API
  module Internal
    class Base < Grape::API
      before { authenticate_by_gitlab_shell_token! }

      before do
        Gitlab::ApplicationContext.push(
          user: -> { actor&.user },
          project: -> { project },
          caller_id: route.origin
        )
      end

      helpers ::API::Helpers::InternalHelpers

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

        def ee_post_receive_response_hook(response)
          # Hook for EE to add messages
        end

        def check_allowed(params)
          # This is a separate method so that EE can alter its behaviour more
          # easily.

          # Stores some Git-specific env thread-safely
          env = parse_env
          Gitlab::Git::HookEnv.set(gl_repository, env) if container

          actor.update_last_used_at!

          check_result = begin
                           access_check!(actor, params)
                         rescue Gitlab::GitAccess::ForbiddenError => e
                           # The return code needs to be 401. If we return 403
                           # the custom message we return won't be shown to the user
                           # and, instead, the default message 'GitLab: API is not accessible'
                           # will be displayed
                           return response_with_status(code: 401, success: false, message: e.message)
                         rescue Gitlab::GitAccess::TimeoutError => e
                           return response_with_status(code: 503, success: false, message: e.message)
                         rescue Gitlab::GitAccess::NotFoundError => e
                           return response_with_status(code: 404, success: false, message: e.message)
                         end

          log_user_activity(actor.user)

          case check_result
          when ::Gitlab::GitAccessResult::Success
            payload = {
              gl_repository: gl_repository,
              gl_project_path: gl_repository_path,
              gl_id: Gitlab::GlId.gl_id(actor.user),
              gl_username: actor.username,
              git_config_options: [],
              gitaly: gitaly_payload(params[:action]),
              gl_console_messages: check_result.console_messages
            }

            # Custom option for git-receive-pack command
            receive_max_input_size = Gitlab::CurrentSettings.receive_max_input_size.to_i
            if receive_max_input_size > 0
              payload[:git_config_options] << "receive.maxInputSize=#{receive_max_input_size.megabytes}"

              if Feature.enabled?(:gitaly_upload_pack_filter, project, default_enabled: true)
                payload[:git_config_options] << "uploadpack.allowFilter=true" << "uploadpack.allowAnySHA1InWant=true"
              end
            end

            response_with_status(**payload)
          when ::Gitlab::GitAccessResult::CustomAction
            response_with_status(code: 300, payload: check_result.payload, gl_console_messages: check_result.console_messages)
          else
            response_with_status(code: 500, success: false, message: UNKNOWN_CHECK_RESULT_ERROR)
          end
        end

        def access_check!(actor, params)
          access_checker = access_checker_for(actor, params[:protocol])
          access_checker.check(params[:action], params[:changes]).tap do |result|
            break result if @project || !repo_type.project?

            # If we have created a project directly from a git push
            # we have to assign its value to both @project and @container
            @project = @container = access_checker.project
          end
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
        #   check_ip - optional, only in EE version, may limit access to
        #     group resources based on its IP restrictions
        post "/allowed" do
          if repo_type.snippet? && params[:protocol] != 'web' && Feature.disabled?(:version_snippets, actor.user)
            break response_with_status(code: 401, success: false, message: 'Snippet git access is disabled.')
          end

          # It was moved to a separate method so that EE can alter its behaviour more
          # easily.
          check_allowed(params)
        end

        post "/lfs_authenticate" do
          status 200

          unless actor.key_or_user
            raise ActiveRecord::RecordNotFound.new('User not found!')
          end

          actor.update_last_used_at!

          Gitlab::LfsToken
            .new(actor.key_or_user)
            .authentication_payload(lfs_authentication_url(project))
        end

        #
        # Get a ssh key using the fingerprint
        #
        # rubocop: disable CodeReuse/ActiveRecord
        get '/authorized_keys' do
          fingerprint = params.fetch(:fingerprint) do
            Gitlab::InsecureKeyFingerprint.new(params.fetch(:key)).fingerprint
          end
          key = Key.find_by(fingerprint: fingerprint)
          not_found!('Key') if key.nil?
          present key, with: Entities::SSHKey
        end
        # rubocop: enable CodeReuse/ActiveRecord

        #
        # Discover user by ssh key, user id or username
        #
        get '/discover' do
          present actor.user, with: Entities::UserSafe
        end

        get '/check' do
          {
            api_version: API.version,
            gitlab_version: Gitlab::VERSION,
            gitlab_rev: Gitlab.revision,
            redis: redis_ping
          }
        end
        post '/two_factor_recovery_codes' do
          status 200

          actor.update_last_used_at!
          user = actor.user

          if params[:key_id]
            unless actor.key
              break { success: false, message: 'Could not find the given key' }
            end

            if actor.key.is_a?(DeployKey)
              break { success: false, message: 'Deploy keys cannot be used to retrieve recovery codes' }
            end

            unless user
              break { success: false, message: 'Could not find a user for the given key' }
            end
          elsif params[:user_id] && user.nil?
            break { success: false, message: 'Could not find the given user' }
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

        post '/pre_receive' do
          status 200

          reference_counter_increased = Gitlab::ReferenceCounter.new(params[:gl_repository]).increase

          { reference_counter_increased: reference_counter_increased }
        end

        post '/post_receive' do
          status 200

          response = PostReceiveService.new(actor.user, repository, project, params).execute

          ee_post_receive_response_hook(response)

          present response, with: Entities::InternalPostReceive::Response
        end
      end
    end
  end
end

API::Internal::Base.prepend_if_ee('EE::API::Internal::Base')
