module API
  module Helpers
    module InternalHelpers
      def wiki?
        set_project unless defined?(@wiki)
        @wiki
      end

      def project
        set_project unless defined?(@project)
        @project
      end
      
      def redirected_path
        @redirected_path
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

      private

      def set_project
        if params[:gl_repository]
          @project, @wiki = Gitlab::GlRepository.parse(params[:gl_repository])
          @redirected_path = nil
        else
          @project, @wiki, @redirected_path = Gitlab::RepoPath.parse(params[:project])
        end
      end

      # Project id to pass between components that don't share/don't have
      # access to the same filesystem mounts
      def gl_repository
        Gitlab::GlRepository.gl_repository(project, wiki?)
      end

      # Return the repository full path so that gitlab-shell has it when
      # handling ssh commands
      def repository_path
        if wiki?
          project.wiki.repository.path_to_repo
        else
          project.repository.path_to_repo
        end
      end
    end
  end
end
