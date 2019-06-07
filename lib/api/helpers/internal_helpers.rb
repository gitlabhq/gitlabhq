# frozen_string_literal: true

module API
  module Helpers
    module InternalHelpers
      attr_reader :redirected_path

      delegate :wiki?, to: :repo_type

      def repo_type
        set_project unless defined?(@repo_type) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @repo_type # rubocop:disable Gitlab/ModuleWithInstanceVariables
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

      def process_mr_push_options(push_options, project, user, changes)
        output = {}

        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/61359')

        service = ::MergeRequests::PushOptionsHandlerService.new(
          project,
          user,
          changes,
          push_options
        ).execute

        if service.errors.present?
          output[:warnings] = push_options_warning(service.errors.join("\n\n"))
        end

        output
      end

      def push_options_warning(warning)
        options = Array.wrap(params[:push_options]).map { |p| "'#{p}'" }.join(' ')
        "Error encountered with push options #{options}: #{warning}"
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
          @project, @repo_type = Gitlab::GlRepository.parse(params[:gl_repository])
          @redirected_path = nil
        else
          @project, @repo_type, @redirected_path = Gitlab::RepoPath.parse(params[:project])
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      # Project id to pass between components that don't share/don't have
      # access to the same filesystem mounts
      def gl_repository
        repo_type.identifier_for_subject(project)
      end

      def gl_project_path
        if wiki?
          project.wiki.full_path
        else
          project.full_path
        end
      end

      # Return the repository depending on whether we want the wiki or the
      # regular repository
      def repository
        if repo_type.wiki?
          project.wiki.repository
        else
          project.repository
        end
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
