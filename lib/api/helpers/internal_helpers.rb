# frozen_string_literal: true

module API
  module Helpers
    module InternalHelpers
      attr_reader :redirected_path

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

      def access_checker_for(actor, protocol)
        access_checker_klass.new(actor.key_or_user, container, protocol,
          authentication_abilities: ssh_authentication_abilities,
          repository_path: repository_path,
          redirected_path: redirected_path)
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

        ::Users::ActivityService.new(actor).execute if commands.include?(params[:action])
      end

      def redis_ping
        result = Gitlab::Redis::SharedState.with { |redis| redis.ping }

        result == 'PONG'
      rescue StandardError => e
        Gitlab::AppLogger.warn("GitLab: An unexpected error occurred in pinging to Redis: #{e}")
        false
      end

      private

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
          features: Feature::Gitaly.server_feature_flags(repository.project)
        }
      end
    end
  end
end
