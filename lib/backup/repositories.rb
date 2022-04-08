# frozen_string_literal: true

require 'yaml'

module Backup
  class Repositories < Task
    extend ::Gitlab::Utils::Override

    def initialize(progress, strategy:)
      super(progress)

      @strategy = strategy
    end

    override :dump
    def dump(path, backup_id)
      strategy.start(:create, path, backup_id: backup_id)
      enqueue_consecutive

    ensure
      strategy.finish!
    end

    override :restore
    def restore(path)
      strategy.start(:restore, path)
      enqueue_consecutive

    ensure
      strategy.finish!

      cleanup_snippets_without_repositories
      restore_object_pools
    end

    private

    attr_reader :strategy

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
      Snippet.find_each(batch_size: 1000) { |snippet| enqueue_snippet(snippet) }
    end

    def enqueue_project(project)
      strategy.enqueue(project, Gitlab::GlRepository::PROJECT)
      strategy.enqueue(project, Gitlab::GlRepository::WIKI)
      strategy.enqueue(project, Gitlab::GlRepository::DESIGN)
    end

    def enqueue_snippet(snippet)
      strategy.enqueue(snippet, Gitlab::GlRepository::SNIPPET)
    end

    def project_relation
      Project.includes(:route, :group, namespace: :owner)
    end

    def restore_object_pools
      PoolRepository.includes(:source_project).find_each do |pool|
        progress.puts " - Object pool #{pool.disk_path}..."

        pool.source_project ||= pool.member_projects.first&.root_of_fork_network
        unless pool.source_project
          progress.puts " - Object pool #{pool.disk_path}... " + "[SKIPPED]".color(:cyan)
          next
        end

        pool.state = 'none'
        pool.save

        pool.schedule
      end
    end

    # Snippets without a repository should be removed because they failed to import
    # due to having invalid repositories
    def cleanup_snippets_without_repositories
      invalid_snippets = []

      Snippet.find_each(batch_size: 1000).each do |snippet|
        response = Snippets::RepositoryValidationService.new(nil, snippet).execute
        next if response.success?

        snippet.repository.remove
        progress.puts("Snippet #{snippet.full_path} can't be restored: #{response.message}")

        invalid_snippets << snippet.id
      end

      Snippet.id_in(invalid_snippets).delete_all
    end
  end
end

Backup::Repositories.prepend_mod_with('Backup::Repositories')
