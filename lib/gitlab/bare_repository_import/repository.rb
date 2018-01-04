module Gitlab
  module BareRepositoryImport
    class Repository
      attr_reader :group_path, :project_name, :repo_path

      def initialize(root_path, repo_path)
        @root_path = root_path
        @repo_path = repo_path
        @root_path << '/' unless root_path.ends_with?('/')

        full_path =
          if hashed? && !wiki?
            repository.config.get('gitlab.fullpath')
          else
            repo_relative_path
          end

        # Split path into 'all/the/namespaces' and 'project_name'
        @group_path, _, @project_name = full_path.to_s.rpartition('/')
      end

      def wiki_exists?
        File.exist?(wiki_path)
      end

      def wiki_path
        @wiki_path ||= repo_path.sub(/\.git$/, '.wiki.git')
      end

      def project_full_path
        @project_full_path ||= "#{group_path}/#{project_name}"
      end

      def processable?
        return false if wiki?
        return false if hashed? && (group_path.blank? || project_name.blank?)

        true
      end

      private

      def wiki?
        @wiki ||= repo_path.end_with?('.wiki.git')
      end

      def hashed?
        @hashed ||= repo_relative_path.include?('@hashed')
      end

      def repo_relative_path
        # Remove root path and `.git` at the end
        repo_path[@root_path.size...-4]
      end

      def repository
        @repository ||= Rugged::Repository.new(repo_path)
      end
    end
  end
end
