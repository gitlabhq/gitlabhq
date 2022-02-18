# frozen_string_literal: true

module API
  module ProjectsRelationBuilder
    extend ActiveSupport::Concern

    class_methods do
      def prepare_relation(projects_relation, options = {})
        projects_relation = preload_relation(projects_relation, options)

        execute_batch_counting(projects_relation)

        preload_repository_cache(projects_relation)

        Preloaders::UserMaxAccessLevelInProjectsPreloader.new(projects_relation, options[:current_user]).execute if options[:current_user]
        Preloaders::SingleHierarchyProjectGroupPlansPreloader.new(projects_relation).execute if options[:single_hierarchy]

        projects_relation
      end

      # This is overridden by the specific Entity class to
      # preload assocations that it needs
      def preload_relation(projects_relation, options = {})
        projects_relation
      end

      # This is overridden by the specific Entity class to
      # batch load certain counts
      def execute_batch_counting(projects_relation)
      end

      def preload_repository_cache(projects_relation)
        repositories = repositories_for_preload(projects_relation)

        Gitlab::RepositoryCache::Preloader.new(repositories).preload( # rubocop:disable CodeReuse/ActiveRecord
          %i[exists? root_ref has_visible_content? avatar readme_path]
        )
      end

      def repositories_for_preload(projects_relation)
        projects_relation.map(&:repository)
      end
    end
  end
end
