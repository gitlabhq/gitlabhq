module Gitlab
  module ImportExport
    class RepoRestorer
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, path:)
        @project = project
        # TODO remove magic keyword and move it to a shared config
        @path = File.join(path, 'project.bundle')
      end

      def restore
        return false unless File.exists?(@path)
        # Move repos dir to 'repositories.old' dir

        FileUtils.mkdir_p(repos_path)
        FileUtils.mkdir_p(path_to_repo)
        untar_xf(archive: @path, dir: path_to_repo)
      end

      private

      def repos_path
        Gitlab.config.gitlab_shell.repos_path
      end

      def path_to_repo
        @project.repository.path_to_repo
      end
    end
  end
end
