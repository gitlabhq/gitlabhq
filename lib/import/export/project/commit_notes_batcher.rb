# frozen_string_literal: true

module Import
  module Export
    module Project
      class CommitNotesBatcher
        DEFAULT_BATCH_SIZE = 500

        RETRIABLE_GITALY_ERRORS = [GRPC::Unavailable, GRPC::DeadlineExceeded].freeze
        MAX_TRIES = 3

        def initialize(project, batch_size: DEFAULT_BATCH_SIZE)
          @project = project
          @batch_size = batch_size
        end

        # Walks every commit reachable from the repository's refs (Gitaly
        # ListCommits, paginating by @batch_size, and yields each page as
        # an array of commit SHAs
        def each_batch
          return enum_for(:each_batch) unless block_given?
          return unless @project.repository.exists?

          cursor = nil

          loop do
            response = list_commits(cursor)
            break if response.empty?

            yield response.map(&:id)

            cursor = response.next_cursor
            break if cursor.blank?
          end
        end

        # Yields batches of project's commit-note IDs, accumulated up to @batch_size
        def each_commit_note_id_batch
          return enum_for(:each_commit_note_id_batch) unless block_given?

          buffer = []

          each_batch do |shas|
            buffer.concat(commit_note_ids_for(shas))

            yield buffer.shift(@batch_size) while buffer.size >= @batch_size
          end

          yield buffer if buffer.any?
        end

        private

        def list_commits(cursor)
          Retriable.retriable(on: RETRIABLE_GITALY_ERRORS, tries: MAX_TRIES) do
            @project.repository.raw_repository.gitaly_commit_client.list_commits(
              ['--all'],
              pagination_params: { page_token: cursor, limit: @batch_size }
            )
          end
        end

        def commit_note_ids_for(shas)
          Note.commit_note_ids_for_shas(shas, @project.id)
        end
      end
    end
  end
end
