# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will fill the project_repositories table for projects that
    # are on hashed storage and an entry is missing in this table.
    class BackfillSnippetRepositories
      MAX_RETRIES = 2

      def perform(start_id, stop_id)
        snippets = snippet_relation.where(id: start_id..stop_id)

        migrate_snippets(snippets)
      end

      def perform_by_ids(snippet_ids)
        snippets = snippet_relation.where(id: snippet_ids)

        migrate_snippets(snippets)
      end

      private

      def migrate_snippets(snippets)
        snippets.find_each do |snippet|
          # We need to expire the exists? value for the cached method in case it was cached
          snippet.repository.expire_exists_cache

          next if repository_present?(snippet)

          retry_index = 0
          @invalid_path_error = false
          @invalid_signature_error = false

          begin
            create_repository_and_files(snippet)

            logger.info(message: 'Snippet Migration: repository created and migrated', snippet: snippet.id)
          rescue StandardError => e
            set_file_path_error(e)
            set_signature_error(e)

            retry_index += 1

            retry if retry_index < max_retries

            logger.error(message: "Snippet Migration: error migrating snippet. Reason: #{e.message}", snippet: snippet.id)

            destroy_snippet_repository(snippet)
            delete_repository(snippet)
          end
        end
      end

      def snippet_relation
        @snippet_relation ||= Snippet.includes(:author, snippet_repository: :shard)
      end

      def repository_present?(snippet)
        snippet.snippet_repository && !snippet.empty_repo?
      end

      def create_repository_and_files(snippet)
        snippet.create_repository
        create_commit(snippet)
      end

      # Removing the db record
      def destroy_snippet_repository(snippet)
        snippet.snippet_repository&.delete
      rescue StandardError => e
        logger.error(message: "Snippet Migration: error destroying snippet repository. Reason: #{e.message}", snippet: snippet.id)
      end

      # Removing the repository in disk
      def delete_repository(snippet)
        return unless snippet.repository_exists?

        snippet.repository.remove
        snippet.repository.expire_exists_cache
      rescue StandardError => e
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
        file_name = snippet.file_name
        file_name = file_name.parameterize if @invalid_path_error

        file_name.presence || empty_file_name
      end

      def empty_file_name
        @empty_file_name ||= "#{SnippetRepository::DEFAULT_EMPTY_FILE_NAME}1.txt"
      end

      def commit_attrs
        @commit_attrs ||= { branch_name: 'main', message: 'Initial commit' }
      end

      def create_commit(snippet)
        snippet.snippet_repository.multi_files_action(commit_author(snippet), snippet_action(snippet), **commit_attrs)
      end

      # If the user is not allowed to access git or update the snippet
      # because it is blocked, internal, ghost, ... we cannot commit
      # files because these users are not allowed to, but we need to
      # migrate their snippets as well.
      # In this scenario the migration bot user will be the one that will commit the files.
      def commit_author(snippet)
        return migration_bot_user if snippet_content_size_over_limit?(snippet)
        return migration_bot_user if @invalid_signature_error

        if Gitlab::UserAccessSnippet.new(snippet.author, snippet: snippet).can_do_action?(:update_snippet)
          snippet.author
        else
          migration_bot_user
        end
      end

      def migration_bot_user
        @migration_bot_user ||= User.migration_bot
      end

      # We sometimes receive invalid path errors from Gitaly if the Snippet filename
      # cannot be parsed into a valid git path.
      # In this situation, we need to parameterize the file name of the Snippet so that
      # the migration can succeed, to achieve that, we'll identify in migration retries
      # that the path is invalid
      def set_file_path_error(error)
        @invalid_path_error ||= error.is_a?(SnippetRepository::InvalidPathError)
      end

      # We sometimes receive invalid signature from Gitaly if the commit author
      # name or email is invalid to create the commit signature.
      # In this situation, we set the error and use the migration_bot since
      # the information used to build it is valid
      def set_signature_error(error)
        @invalid_signature_error ||= error.is_a?(SnippetRepository::InvalidSignatureError)
      end

      # In the case where the snippet file_name is invalid and also the
      # snippet author has invalid commit info, we need to increase the
      # number of retries by 1, because we will receive two errors
      # from Gitaly and, in the third one, we will commit successfully.
      def max_retries
        MAX_RETRIES + (@invalid_signature_error && @invalid_path_error ? 1 : 0)
      end

      def snippet_content_size_over_limit?(snippet)
        snippet.content.size > Gitlab::CurrentSettings.snippet_size_limit
      end
    end
  end
end
