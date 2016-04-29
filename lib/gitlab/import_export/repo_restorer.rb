module Gitlab
  module ImportExport
    class RepoRestorer
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project: , path:, bundler_file: )
        @project = project
        @path = File.join(path, bundler_file)
      end

      def restore
        return false unless File.exists?(@path)
          # Move repos dir to 'repositories.old' dir

        FileUtils.mkdir_p(repos_path)
        FileUtils.mkdir_p(path_to_repo)
        untar_zxf(archive: @path, dir: path_to_repo)
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
