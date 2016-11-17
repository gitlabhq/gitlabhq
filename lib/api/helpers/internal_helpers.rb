module API
  module Helpers
    module InternalHelpers
      # Project paths may be any of the following:
      #   * /repository/storage/path/namespace/project
      #   * /namespace/project
      #   * namespace/project
      #
      # In addition, they may have a '.git' extension and multiple namespaces
      #
      # Transform all these cases to 'namespace/project'
      def clean_project_path(project_path, storage_paths = Repository.storages.values)
        project_path = project_path.sub(/\.git\z/, '')

        storage_paths.each do |storage_path|
          storage_path = File.expand_path(storage_path)

          if project_path.start_with?(storage_path)
            project_path = project_path.sub(storage_path, '')
            break
          end
        end

        project_path.sub(/\A\//, '')
      end

      def project_path
        @project_path ||= clean_project_path(params[:project])
      end

      def wiki?
        @wiki ||= project_path.end_with?('.wiki') &&
          !Project.find_with_namespace(project_path)
      end

      def project
        @project ||= begin
          # Check for *.wiki repositories.
          # Strip out the .wiki from the pathname before finding the
          # project. This applies the correct project permissions to
          # the wiki repository as well.
          project_path.chomp!('.wiki') if wiki?

          Project.find_with_namespace(project_path)
        end
      end

      def ssh_authentication_abilities
        [
          :read_project,
          :download_code,
          :push_code
        ]
      end

      def log_user_activity(actor)
        commands = Gitlab::GitAccess::DOWNLOAD_COMMANDS +
                    Gitlab::GitAccess::PUSH_COMMANDS +
                    Gitlab::GitAccess::GIT_ANNEX_COMMANDS

        ::Users::ActivityService.new(actor, 'Git SSH').execute if commands.include?(params[:action])
      end
    end
  end
end
