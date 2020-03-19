# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will fill the project_repositories table for projects that
    # are on hashed storage and an entry is missing in this table.
    class BackfillSnippetRepositories
      MAX_RETRIES = 2

      def perform(start_id, stop_id)
        Snippet.includes(:author, snippet_repository: :shard).where(id: start_id..stop_id).find_each do |snippet|
          # We need to expire the exists? value for the cached method in case it was cached
          snippet.repository.expire_exists_cache

          next if repository_present?(snippet)

          retry_index = 0

          begin
            create_repository_and_files(snippet)

            logger.info(message: 'Snippet Migration: repository created and migrated', snippet: snippet.id)
          rescue => e
            retry_index += 1

            retry if retry_index < MAX_RETRIES

            logger.error(message: "Snippet Migration: error migrating snippet. Reason: #{e.message}", snippet: snippet.id)

            destroy_snippet_repository(snippet)
            delete_repository(snippet)
          end
        end
      end

      private

      def repository_present?(snippet)
        snippet.snippet_repository && !snippet.empty_repo?
      end

      def create_repository_and_files(snippet)
        snippet.create_repository
        create_commit(snippet)
      end

      def destroy_snippet_repository(snippet)
        # Removing the db record
        snippet.snippet_repository&.destroy
      rescue => e
        logger.error(message: "Snippet Migration: error destroying snippet repository. Reason: #{e.message}", snippet: snippet.id)
      end

      def delete_repository(snippet)
        # Removing the repository in disk
        snippet.repository.remove if snippet.repository_exists?
      rescue => e
        logger.error(message: "Snippet Migration: error deleting repository. Reason: #{e.message}", snippet: snippet.id)
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end

      def snippet_action(snippet)
        # We don't need the previous_path param
        # Because we're not updating any existing file
        [{ file_path: filename(snippet),
           content: snippet.content }]
      end

      def filename(snippet)
        snippet.file_name.presence || empty_file_name
      end

      def empty_file_name
        @empty_file_name ||= "#{SnippetRepository::DEFAULT_EMPTY_FILE_NAME}1.txt"
      end

      def commit_attrs
        @commit_attrs ||= { branch_name: 'master', message: 'Initial commit' }
      end

      def create_commit(snippet)
        snippet.snippet_repository.multi_files_action(snippet.author, snippet_action(snippet), commit_attrs)
      end
    end
  end
end
