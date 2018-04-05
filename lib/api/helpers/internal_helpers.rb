module API
  module Helpers
    module InternalHelpers
      attr_reader :redirected_path

      def wiki?
        set_project unless defined?(@wiki) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @wiki # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def project
        set_project unless defined?(@project) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @project # rubocop:disable Gitlab/ModuleWithInstanceVariables
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

        JSON.parse(params[:env])
      rescue JSON::ParserError
        {}
      end

      def log_user_activity(actor)
        commands = Gitlab::GitAccess::DOWNLOAD_COMMANDS

        ::Users::ActivityService.new(actor, 'Git SSH').execute if commands.include?(params[:action])
      end

      def merge_request_urls
        ::MergeRequests::GetUrlsService.new(project).execute(params[:changes])
      end

      def redis_ping
        result = Gitlab::Redis::SharedState.with { |redis| redis.ping }

        result == 'PONG'
      rescue => e
        Rails.logger.warn("GitLab: An unexpected error occurred in pinging to Redis: #{e}")
        false
      end

      def project_path
        project&.path || project_path_match[:project_path]
      end

      def namespace_path
        project&.namespace&.full_path || project_path_match[:namespace_path]
      end

      private

      def project_path_match
        @project_path_match ||= params[:project].match(Gitlab::PathRegex.full_project_git_path_regex) || {}
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def set_project
        if params[:gl_repository]
          @project, @wiki = Gitlab::GlRepository.parse(params[:gl_repository])
          @redirected_path = nil
        else
          @project, @wiki, @redirected_path = Gitlab::RepoPath.parse(params[:project])
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      # Project id to pass between components that don't share/don't have
      # access to the same filesystem mounts
      def gl_repository
        Gitlab::GlRepository.gl_repository(project, wiki?)
      end

      # Return the repository depending on whether we want the wiki or the
      # regular repository
      def repository
        if wiki?
          project.wiki.repository
        else
          project.repository
        end
      end

      # Return the repository full path so that gitlab-shell has it when
      # handling ssh commands
      def repository_path
        repository.path_to_repo
      end

      # Return the Gitaly Address if it is enabled
      def gitaly_payload(action)
        return unless %w[git-receive-pack git-upload-pack git-upload-archive].include?(action)

        {
          repository: repository.gitaly_repository,
          address: Gitlab::GitalyClient.address(project.repository_storage),
          token: Gitlab::GitalyClient.token(project.repository_storage)
        }
      end
    end
  end
end
