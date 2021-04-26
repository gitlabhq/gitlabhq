# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class creates/updates those personal snippets statistics
    # that haven't been created nor initialized.
    # It also updates the related root storage namespace stats
    class PopulatePersonalSnippetStatistics
      def perform(snippet_ids)
        personal_snippets(snippet_ids).group_by(&:author).each do |author, author_snippets|
          upsert_snippet_statistics(author_snippets)
          update_namespace_statistics(author.namespace)
        end
      end

      private

      def personal_snippets(snippet_ids)
        PersonalSnippet
          .where(id: snippet_ids)
          .includes(author: :namespace)
          .includes(:statistics)
          .includes(snippet_repository: :shard)
      end

      def upsert_snippet_statistics(snippets)
        snippets.each do |snippet|
          response = Snippets::UpdateStatisticsService.new(snippet).execute

          error_message("#{response.message} snippet: #{snippet.id}") if response.error?
        end
      end

      def update_namespace_statistics(namespace)
        Namespaces::StatisticsRefresherService.new.execute(namespace)
      rescue StandardError => e
        error_message("Error updating statistics for namespace #{namespace.id}: #{e.message}")
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end

      def error_message(message)
        logger.error(message: "Snippet Statistics Migration: #{message}")
      end
    end
  end
end
