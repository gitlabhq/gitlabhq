# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class creates/updates those project snippets statistics
    # that haven't been created nor initialized.
    # It also updates the related project statistics and its root storage namespace stats
    class PopulateProjectSnippetStatistics
      def perform(snippet_ids)
        project_snippets(snippet_ids).group_by(&:namespace_id).each do |namespace_id, namespace_snippets|
          namespace_snippets.group_by(&:project).each do |project, snippets|
            upsert_snippet_statistics(snippets)
            update_project_statistics(project)
          rescue StandardError
            error_message("Error updating statistics for project #{project.id}")
          end

          update_namespace_statistics(namespace_snippets.first.project.root_namespace)
        rescue StandardError => e
          error_message("Error updating statistics for namespace #{namespace_id}: #{e.message}")
        end
      end

      private

      def project_snippets(snippet_ids)
        ProjectSnippet
          .select('snippets.*, projects.namespace_id')
          .where(id: snippet_ids)
          .joins(:project)
          .includes(:statistics)
          .includes(snippet_repository: :shard)
          .includes(project: [:route, :statistics, :namespace])
      end

      def upsert_snippet_statistics(snippets)
        snippets.each do |snippet|
          response = Snippets::UpdateStatisticsService.new(snippet).execute

          error_message("#{response.message} snippet: #{snippet.id}") if response.error?
        end
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end

      def error_message(message)
        logger.error(message: "Snippet Statistics Migration: #{message}")
      end

      def update_project_statistics(project)
        project.statistics&.refresh!(only: [:snippets_size])
      end

      def update_namespace_statistics(namespace)
        Namespaces::StatisticsRefresherService.new.execute(namespace)
      end
    end
  end
end
