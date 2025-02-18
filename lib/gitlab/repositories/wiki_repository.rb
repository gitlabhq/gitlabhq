# frozen_string_literal: true

module Gitlab
  module Repositories
    class WikiRepository < Gitlab::Repositories::RepoType
      include Singleton
      extend Gitlab::Utils::Override

      override :name
      def name = :wiki

      override :suffix
      def suffix = :wiki

      override :access_checker_class
      def access_checker_class = Gitlab::GitAccessWiki

      override :guest_read_ability
      def guest_read_ability = :download_wiki_code

      override :container_class
      def container_class = ProjectWiki

      override :project_for
      def project_for(wiki)
        wiki.try(:project)
      end

      private

      override :repository_resolver
      def repository_resolver(container)
        # Also allow passing a Project, Group, or Geo::DeletedProject
        wiki = container.is_a?(Wiki) ? container : container.wiki

        ::Repository.new(
          wiki.full_path,
          wiki,
          shard: wiki.repository_storage,
          disk_path: wiki.disk_path,
          repo_type: Gitlab::GlRepository::WIKI
        )
      end

      override :check_container
      def check_container(container)
        # Don't check container for wikis because it accepts several container types.
      end
    end
  end
end
