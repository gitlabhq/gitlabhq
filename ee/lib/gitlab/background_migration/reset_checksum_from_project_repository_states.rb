# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class ResetChecksumFromProjectRepositoryStates
      def perform(start_id, stop_id)
        ProjectRepositoryState
          .where(project_id: start_id..stop_id)
          .update_all(
            repository_verification_checksum: nil,
            wiki_verification_checksum: nil,
            last_repository_verification_failure: nil,
            last_wiki_verification_failure: nil,
            repository_retry_at: nil,
            wiki_retry_at: nil,
            repository_retry_count: nil,
            wiki_retry_count: nil
          )
      end
    end
  end
end
