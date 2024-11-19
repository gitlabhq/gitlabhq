# frozen_string_literal: true

require 'yaml'

module Backup
  module Targets
    # Backup and restores repositories by querying the database
    class Repositories < Target
      extend ::Gitlab::Utils::Override

      # @param [IO] progress IO interface to output progress
      # @param [Object] :strategy Fetches backups from gitaly
      # @param [Array<String>] :storages Filter by specified storage names. Empty means all storages.
      # @param [Array<String>] :paths Filter by specified project paths. Empty means all projects, groups, and snippets.
      # @param [Array<String>] :skip_paths Skip specified project paths. Empty means all projects, groups, and snippets.
      def initialize(progress, strategy:, options:, storages: [], paths: [], skip_paths: [])
        super(progress, options: options)

        @strategy = strategy
        @storages = storages
        @paths = paths
        @skip_paths = skip_paths
        @logger = Gitlab::BackupLogger.new(progress)
      end

      override :dump

      def dump(destination_path, backup_id)
        strategy.start(:create, destination_path, backup_id: backup_id)
        enqueue_consecutive

      ensure
        strategy.finish!
      end

      override :restore

      def restore(destination_path, backup_id)
        strategy.start(:restore,
          destination_path,
          remove_all_repositories: remove_all_repositories,
          backup_id: backup_id)
        enqueue_consecutive

      ensure
        begin
          strategy.finish!

        rescue Error => e
          logger.error(e.message)
        end

        restore_object_pools
      end

      def asynchronous?
        false
      end

      private

      attr_reader :strategy, :storages, :paths, :skip_paths, :logger

      def remove_all_repositories
        return if paths.present?

        storages.presence || Gitlab.config.repositories.storages.keys
      end

      def enqueue_consecutive
        enqueue_consecutive_projects
        enqueue_consecutive_snippets
      end

      def enqueue_consecutive_projects
        project_relation.find_each(batch_size: 1000) do |project|
          enqueue_project(project)
        end
      end

      def enqueue_consecutive_snippets
        snippet_relation.find_each(batch_size: 1000) { |snippet| enqueue_snippet(snippet) }
      end

      def enqueue_project(project)
        strategy.enqueue(project, Gitlab::GlRepository::PROJECT)
        strategy.enqueue(project, Gitlab::GlRepository::WIKI)

        return unless project.design_management_repository

        strategy.enqueue(project.design_management_repository, Gitlab::GlRepository::DESIGN)
      end

      def enqueue_snippet(snippet)
        strategy.enqueue(snippet, Gitlab::GlRepository::SNIPPET)
      end

      def project_relation
        scope = Project.includes(:route, :group, :namespace)
        scope = scope.id_in(ProjectRepository.for_repository_storage(storages).select(:project_id)) if storages.any?
        if paths.any?
          scope = scope.where_full_path_in(paths).or(
            Project.where(namespace_id: Namespace.where_full_path_in(paths).self_and_descendants)
          )
        end

        scope = scope.and(skipped_path_relation) if skip_paths.any?
        scope
      end

      def snippet_relation
        scope = Snippet.all
        scope = scope.id_in(SnippetRepository.for_repository_storage(storages).select(:snippet_id)) if storages.any?
        if paths.any?
          scope = scope.joins(:project).merge(
            Project.where_full_path_in(paths).or(
              Project.where(namespace_id: Namespace.where_full_path_in(paths).self_and_descendants)
            )
          )
        end

        if skip_paths.any?
          scope = scope.where(project: skipped_path_relation)
          scope = scope.or(Snippet.where(project: nil)) if !paths.any? && !storages.any?
        end

        scope
      end

      def skipped_path_relation
        Project.where.not(id: Project.where_full_path_in(skip_paths).or(
          Project.where(namespace_id: Namespace.where_full_path_in(skip_paths).self_and_descendants)
        ))
      end

      def restore_object_pools
        PoolRepository.includes(:source_project).find_each do |pool|
          logger.info " - Object pool #{pool.disk_path}..."

          unless pool.source_project
            logger.info " - Object pool #{pool.disk_path}... [SKIPPED]"
            next
          end

          pool.state = 'none'
          pool.save

          pool.schedule
        end
      end
    end
  end
end

Backup::Targets::Repositories.prepend_mod_with('Backup::Targets::Repositories')
