# frozen_string_literal: true

module API
  # Internal access API
  module Internal
    class Base < ::API::Base
      include Gitlab::RackLoadBalancingHelpers

      before { authenticate_by_gitlab_shell_token! }

      before do
        api_endpoint = env['api.endpoint']
        feature_category = api_endpoint.options[:for].try(:feature_category_for_app, api_endpoint).to_s

        if actor.user
          load_balancer_stick_request(::User, :user, actor.user.id)
          set_current_organization(user: actor.user)
          link_scoped_user(params)
        end

        Gitlab::ApplicationContext.push(
          user: -> { actor&.user },
          project: -> { project },
          caller_id: api_endpoint.endpoint_id,
          remote_ip: request.ip,
          feature_category: feature_category
        )
      end

      helpers ::API::Helpers::InternalHelpers

      VALID_PAT_SCOPES = Set.new(
        Gitlab::Auth::API_SCOPES + Gitlab::Auth::REPOSITORY_SCOPES + Gitlab::Auth::REGISTRY_SCOPES
      ).freeze

      helpers do
        def lfs_authentication_url(container)
          # This is a separate method so that EE can alter its behaviour more
          # easily.
          container.lfs_http_url_to_repo
        end

        def link_scoped_user(params)
          context = gitaly_context(params)

          return unless context

          scoped_user_id = context['scoped-user-id']

          return unless scoped_user_id.present?

          scoped_user_id = scoped_user_id.to_i
          identity = ::Gitlab::Auth::Identity.link_from_scoped_user_id(actor.user, scoped_user_id)

          not_found!("User ID #{scoped_user_id} not found") unless identity
        end

        # rubocop: disable Metrics/AbcSize
        def check_allowed(params)
          # This is a separate method so that EE can alter its behaviour more
          # easily.

          check_rate_limit!(:gitlab_shell_operation, scope: [params[:action], params[:project], actor.key_or_user])

          rate_limiter = Gitlab::Auth::IpRateLimiter.new(request.ip)

          unless rate_limiter.trusted_ip?
            check_rate_limit!(:gitlab_shell_operation, scope: [params[:action], params[:project], rate_limiter.ip])
          end

          # Stores some Git-specific env thread-safely
          #
          # Snapshot repositories have different relative path than the main repository. For access
          # checks that need quarantined objects the relative path in also sent with Gitaly RPCs
          # calls as a header.
          Gitlab::Git::HookEnv.set(gl_repository, params[:relative_path], parse_env) if container

          actor.update_last_used_at!

          check_result = access_check_result
          return check_result if unsuccessful_response?(check_result)

          log_user_activity(actor.user)

          case check_result
          when ::Gitlab::GitAccessResult::Success
            payload = {
              gl_repository: gl_repository,
              gl_project_path: gl_repository_path,
              gl_project_id: project&.id,
              gl_root_namespace_id: project&.root_namespace&.id,
              gl_id: Gitlab::GlId.gl_id(actor.user),
              gl_username: actor.username,
              git_config_options: ["uploadpack.allowFilter=true",
                                   "uploadpack.allowAnySHA1InWant=true"],
              gitaly: gitaly_payload(params[:action]),
              gl_console_messages: check_result.console_messages,
              need_audit: need_git_audit_event?
            }.merge!(actor.key_details)

            # Custom option for git-receive-pack command

            receive_max_input_size = Gitlab::CurrentSettings.receive_max_input_size.to_i

            if receive_max_input_size > 0
              payload[:git_config_options] << "receive.maxInputSize=#{receive_max_input_size.megabytes}"
            end

            unless Feature.enabled?(:log_git_streaming_audit_events, project)
              send_git_audit_streaming_event(protocol: params[:protocol], action: params[:action])
            end

            response_with_status(**payload)
          when ::Gitlab::GitAccessResult::CustomAction
            response_with_status(code: 300, payload: check_result.payload, gl_console_messages: check_result.console_messages)
          else
            response_with_status(code: 500, success: false, message: ::API::Helpers::InternalHelpers::UNKNOWN_CHECK_RESULT_ERROR)
          end
        end
        # rubocop: enable Metrics/AbcSize

        def validate_actor(actor)
          return 'Could not find the given key' unless actor.key

          'Could not find a user for the given key' unless actor.user
        end

        def two_factor_manual_otp_check
          { success: false, message: 'Feature is not available' }
        end

        def two_factor_push_otp_check
          { success: false, message: 'Feature is not available' }
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
        #   relative_path - relative path of repository having access checks performed.
        #   action - git action (git-upload-pack or git-receive-pack)
        #   changes - changes as "oldrev newrev ref", see Gitlab::ChangesList
        #   gitaly_client_context_bin - context provided by Gitaly client (base64 encoded JSON string)
        #   check_ip - optional, only in EE version, may limit access to
        #     group resources based on its IP restrictions
        #
        # /internal/allowed
        #
        post "/allowed", feature_category: :source_code_management do
          # It was moved to a separate method so that EE can alter its behaviour more
          # easily.
          check_allowed(params)
        end

        # Validate LFS authentication request
        #
        # /internal/lfs_authenticate
        #
        post "/lfs_authenticate", feature_category: :source_code_management, urgency: :high do
          not_found! unless container&.lfs_enabled?

          status 200

          unless actor.key_or_user
            raise ActiveRecord::RecordNotFound, 'User not found!'
          end

          actor.update_last_used_at!

          Gitlab::LfsToken
            .new(actor.key_or_user, container)
            .authentication_payload(lfs_authentication_url(container))
        end

        # Check whether an SSH key is known to GitLab
        #
        # /internal/authorized_keys
        #
        get '/authorized_keys', feature_category: :source_code_management, urgency: :high do
          fingerprint = Gitlab::InsecureKeyFingerprint.new(params.fetch(:key)).fingerprint_sha256

          key = Key.auth.find_by_fingerprint_sha256(fingerprint)
          not_found!('Key') if key.nil?
          present key, with: Entities::SSHKey
        end

        # Discover user by ssh key, user id or username
        #
        # /internal/discover
        #
        get '/discover', feature_category: :system_access do
          present actor.user, with: Entities::UserSafe
        end

        # /internal/check
        #
        get '/check', feature_category: :not_owned do # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
          {
            api_version: API.version,
            gitlab_version: Gitlab::VERSION,
            gitlab_rev: Gitlab.revision,
            redis: redis_ping
          }
        end

        # /internal/two_factor_recovery_codes
        #
        post '/two_factor_recovery_codes', feature_category: :system_access do
          status 200

          actor.update_last_used_at!
          user = actor.user

          error_message = validate_actor(actor)

          if params[:user_id] && user.nil?
            break { success: false, message: 'Could not find the given user' }
          elsif error_message
            break { success: false, message: error_message }
          end

          break { success: false, message: 'Deploy keys cannot be used to retrieve recovery codes' } if actor.key.is_a?(DeployKey)

          unless user.two_factor_enabled?
            break { success: false, message: 'Two-factor authentication is not enabled for this user' }
          end

          codes = nil

          ::Users::UpdateService.new(current_user, user: user).execute! do |user|
            codes = user.generate_otp_backup_codes!
          end

          { success: true, recovery_codes: codes }
        end

        # /internal/personal_access_token
        #
        post '/personal_access_token', feature_category: :system_access do
          status 200

          actor.update_last_used_at!
          user = actor.user

          error_message = validate_actor(actor)

          break { success: false, message: 'Deploy keys cannot be used to create personal access tokens' } if actor.key.is_a?(DeployKey)

          if params[:user_id] && user.nil?
            break { success: false, message: 'Could not find the given user' }
          elsif error_message
            break { success: false, message: error_message }
          end

          if params[:name].blank?
            break { success: false, message: "No token name specified" }
          end

          if params[:scopes].blank?
            break { success: false, message: "No token scopes specified" }
          end

          invalid_scope = params[:scopes].find { |scope| VALID_PAT_SCOPES.exclude?(scope.to_sym) }

          if invalid_scope
            valid_scopes = VALID_PAT_SCOPES.map(&:to_s).sort
            break { success: false, message: "Invalid scope: '#{invalid_scope}'. Valid scopes are: #{valid_scopes}" }
          end

          begin
            expires_at = params[:expires_at].presence && Date.parse(params[:expires_at])
          rescue ArgumentError
            break { success: false, message: "Invalid token expiry date: '#{params[:expires_at]}'" }
          end

          result = ::PersonalAccessTokens::CreateService.new(
            current_user: user, target_user: user, organization_id: Current.organization_id, params: { name: params[:name], scopes: params[:scopes], expires_at: expires_at }
          ).execute

          unless result.status == :success
            break { success: false, message: "Failed to create token: #{result.message}" }
          end

          access_token = result.payload[:personal_access_token]

          { success: true, token: access_token.token, scopes: access_token.scopes, expires_at: access_token.expires_at }
        end

        # /internal/pre_receive
        #
        post '/pre_receive', feature_category: :source_code_management do
          status 200

          reference_counter_increased = Gitlab::ReferenceCounter.new(params[:gl_repository]).increase

          { reference_counter_increased: reference_counter_increased }
        end

        # /internal/post_receive
        #
        post '/post_receive', feature_category: :source_code_management do
          status 200

          response = PostReceiveService.new(actor.user, repository, project, params).execute

          present response, with: Entities::InternalPostReceive::Response
        end

        # This endpoint was added in https://gitlab.com/gitlab-org/gitlab/-/issues/212308
        # It was added with the plan to be used by  GitLab PAM module but we
        # decided to pursue a different approach, so it's currently not used.
        # We might revive the PAM module though as it provides better user
        # flow.
        #
        # /internal/two_factor_config
        #
        post '/two_factor_config', feature_category: :system_access do
          status 200

          break { success: false } unless Feature.enabled?(:two_factor_for_cli)

          actor.update_last_used_at!
          user = actor.user

          error_message = validate_actor(actor)

          if error_message
            { success: false, message: error_message }
          elsif actor.key.is_a?(DeployKey)
            { success: true, two_factor_required: false }
          else
            {
              success: true,
              two_factor_required: user.two_factor_enabled?
            }
          end
        end

        # /internal/two_factor_push_otp_check
        #
        post '/two_factor_push_otp_check', feature_category: :system_access do
          status 200

          two_factor_push_otp_check
        end

        # /internal/two_factor_manual_otp_check
        #
        post '/two_factor_manual_otp_check', feature_category: :system_access do
          status 200

          two_factor_manual_otp_check
        end
      end
    end
  end
end

API::Internal::Base.prepend_mod_with('API::Internal::Base')
