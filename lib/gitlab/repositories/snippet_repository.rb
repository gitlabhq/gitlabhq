# frozen_string_literal: true

module Gitlab
  module Repositories
    class SnippetRepository < Gitlab::Repositories::RepoType
      include Singleton
      extend Gitlab::Utils::Override

      override :name
      def name = :snippet

      override :access_checker_class
      def access_checker_class = Gitlab::GitAccessSnippet

      override :guest_read_ability
      def guest_read_ability = :read_snippet

      override :container_class
      def container_class = Snippet

      override :project_for
      def project_for(snippet)
        snippet&.project
      end

      private

      override :repository_resolver
      def repository_resolver(snippet)
        ::Repository.new(
          snippet.full_path,
          snippet,
          shard: snippet.repository_storage,
          disk_path: snippet.disk_path,
          repo_type: Gitlab::GlRepository::SNIPPET
        )
      end
    end
  end
end
