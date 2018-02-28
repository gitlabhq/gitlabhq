module Gitlab
  module BareRepositoryImport
    class Repository
      attr_reader :group_path, :project_name, :repo_path

      def initialize(root_path, repo_path)
        @root_path = root_path
        @repo_path = repo_path

        # Split path into 'all/the/namespaces' and 'project_name'
        @group_path, _, @project_name = repo_relative_path.rpartition('/')
      end

      def wiki_exists?
        File.exist?(wiki_path)
      end

      def wiki?
        @wiki ||= repo_path.end_with?('.wiki.git')
      end

      def wiki_path
        @wiki_path ||= repo_path.sub(/\.git$/, '.wiki.git')
      end

      def hashed?
        @hashed ||= group_path.start_with?('@hashed')
      end

      def project_full_path
        @project_full_path ||= "#{group_path}/#{project_name}"
      end

      private

      def repo_relative_path
        # Remove root path and `.git` at the end
        repo_path[@root_path.size...-4]
      end
    end
  end
end
