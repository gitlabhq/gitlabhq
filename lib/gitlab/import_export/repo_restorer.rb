module Gitlab
  module ImportExport
    class RepoRestorer
      include Gitlab::ImportExport::CommandLineUtil
      include Gitlab::ShellAdapter

      def initialize(project:, shared:, path_to_bundle:)
        @project = project
        @path_to_bundle = path_to_bundle
        @shared = shared
      end

      def restore
        return true unless File.exist?(@path_to_bundle)

        git_clone_bundle(repo_path: @project.repository.path_to_repo, bundle_path: @path_to_bundle)
      rescue => e
        @shared.error(e)
        false
      end
    end
  end
end
