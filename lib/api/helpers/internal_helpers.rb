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
        else
          @project, @wiki = Gitlab::RepoPath.parse(params[:project])
        end
      end
    end
  end
end
