module Gitlab
  module ImportExport
    class RepoRestorer
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, shared:, path_to_bundle:)
        @project = project
        @path_to_bundle = path_to_bundle
        @shared = shared
      end

      def restore
        return true unless File.exist?(@path_to_bundle)

        mkdir_p(path_to_repo)

        git_unbundle(repo_path: path_to_repo, bundle_path: @path_to_bundle) && repo_restore_hooks
      rescue => e
        @shared.error(e)
        false
      end

      private

      def path_to_repo
        @project.repository.path_to_repo
      end

      def repo_restore_hooks
        return true if wiki?

        git_restore_hooks
      end

      def wiki?
        @project.class.name == 'ProjectWiki'
      end
    end
  end
end
