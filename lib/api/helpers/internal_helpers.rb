# frozen_string_literal: true

module API
  module Helpers
    module InternalHelpers
      attr_reader :redirected_path

      UNKNOWN_CHECK_RESULT_ERROR = 'Unknown check result'

      delegate :wiki?, to: :repo_type

      def actor
        @actor ||= Support::GitAccessActor.from_params(params)
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def repo_type
        parse_repo_path unless defined?(@repo_type)
        @repo_type
      end

      def project
        parse_repo_path unless defined?(@project)
        @project
      end

      def container
        parse_repo_path unless defined?(@container)
        @container
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def access_check_result
        with_admin_mode_bypass!(actor.user&.id) do
          access_check!(actor, params)
        end
      rescue Gitlab::GitAccess::ForbiddenError => e
        # The return code needs to be 401. If we return 403
        # the custom message we return won't be shown to the user
        # and, instead, the default message 'GitLab: API is not accessible'
        # will be displayed
        response_with_status(code: 401, success: false, message: e.message)
      rescue Gitlab::GitAccess::TimeoutError => e
        response_with_status(code: 503, success: false, message: e.message)
      rescue Gitlab::GitAccess::NotFoundError => e
        response_with_status(code: 404, success: false, message: e.message)
      rescue Gitlab::GitAccessProject::CreationError => e
        response_with_status(code: 422, success: false, message: e.message)
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def access_check!(actor, params)
        access_checker = access_checker_for(actor, params[:protocol])
        access_checker.check(params[:action], params[:changes]).tap do |result|
          break result if @project || !repo_type.project?

          # If we have created a project directly from a git push
          # we have to assign its value to both @project and @container
          @project = @container = access_checker.container
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def access_checker_for(actor, protocol)
        access_checker_klass.new(actor.key_or_user, container, protocol,
          authentication_abilities: ssh_authentication_abilities,
          repository_path: repository_path,
          redirected_path: redirected_path,
          push_options: params[:push_options],
          gitaly_context: gitaly_context(params)
        )
      end

      def access_checker_klass
        repo_type.access_checker_class
      end

      def ssh_authentication_abilities
        [
          :read_project,
          :download_code,
          :push_code
        ]
      end

      def parse_env
        return {} if params[:env].blank?

        Gitlab::Json.parse(params[:env])
      rescue JSON::ParserError
        {}
      end

      def log_user_activity(actor)
        commands = Gitlab::GitAccess::DOWNLOAD_COMMANDS

        return unless commands.include?(params[:action])

        ::Users::ActivityService.new(author: actor, namespace: project&.namespace, project: project).execute

        return unless project && actor

        Gitlab::EventStore.publish(
          ::Users::ActivityEvent.new(data: {
            user_id: actor.id,
            namespace_id: project.root_ancestor.id
          })
        )
      end

      def redis_ping
        result = Gitlab::Redis::SharedState.with { |redis| redis.ping }

        result == 'PONG'
      rescue StandardError => e
        Gitlab::AppLogger.warn("GitLab: An unexpected error occurred in pinging to Redis: #{e}")
        false
      end

      def response_with_status(code: 200, success: true, message: nil, **extra_options)
        status code
        { status: success, message: message }.merge(extra_options).compact
      end

      def unsuccessful_response?(response)
        response.is_a?(Hash) && response[:status] == false
      end

      def with_admin_mode_bypass!(actor_id, &block)
        return yield unless Gitlab::CurrentSettings.admin_mode

        Gitlab::Auth::CurrentUserMode.bypass_session!(actor_id, &block)
      end

      def send_git_audit_streaming_event(msg)
        # Defined in EE
      end

      def need_git_audit_event?
        false
      end

      private

      def gitaly_context(params)
        return unless params[:gitaly_client_context_bin].present?

        raw_context = Base64.decode64(params[:gitaly_client_context_bin])
        context = Gitlab::Json.parse(raw_context)

        raise bad_request!('Decoded gitaly_client_context_bin is not a valid JSON object') unless context.is_a?(Hash)

        context
      rescue JSON::ParserError => e
        Gitlab::ErrorTracking.log_exception(e, gitaly_context: params[:gitaly_client_context_bin])
        bad_request!('malformed gitaly_client_context_bin')
      end

      def repository_path
        if container
          "#{container.full_path}.git"
        elsif params[:project]
          # When the project doesn't exist, we still need to pass on the path
          # to support auto-creation in `GitAccessProject`.
          #
          # For consistency with the Git HTTP controllers, we normalize the path
          # to remove a leading slash and ensure a trailing `.git`.
          #
          # NOTE: For GitLab Shell, `params[:project]` is the full repository path
          # from the SSH command, with an optional trailing `.git`.
          "#{params[:project].delete_prefix('/').delete_suffix('.git')}.git"
        end
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def parse_repo_path
        @container, @project, @repo_type, @redirected_path =
          if params[:gl_repository]
            Gitlab::GlRepository.parse(params[:gl_repository])
          elsif params[:project]
            Gitlab::RepoPath.parse(params[:project])
          end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      # Repository id to pass between components that don't share/don't have
      # access to the same filesystem mounts
      def gl_repository
        repo_type.identifier_for_container(container)
      end

      def gl_repository_path
        repository.full_path
      end

      # Return the repository for the detected type and container
      #
      # @returns [Repository]
      def repository
        @repository ||= repo_type.repository_for(container)
      end

      # Return the Gitaly Address if it is enabled
      def gitaly_payload(action)
        return unless %w[git-receive-pack git-upload-pack git-upload-archive].include?(action)

        {
          repository: repository.gitaly_repository.to_h,
          address: Gitlab::GitalyClient.address(repository.shard),
          token: Gitlab::GitalyClient.token(repository.shard),
          features: Feature::Gitaly.server_feature_flags(
            user: ::Feature::Gitaly.user_actor(actor.user),
            repository: repository,
            project: ::Feature::Gitaly.project_actor(repository.container),
            group: ::Feature::Gitaly.group_actor(repository.container)
          )
        }
      end
    end
  end
end

API::Helpers::InternalHelpers.prepend_mod
