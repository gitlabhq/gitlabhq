# frozen_string_literal: true

module Gitlab
  module GithubImport
    class RefreshImportJidWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      include GithubImport::Queue

      def self.perform_in_the_future(*args)
        # Delegate to new version of this job so stale sidekiq nodes can still
        # run instead of no-op
        Gitlab::Import::RefreshImportJidWorker.perform_in_the_future(*args)
      end
    end
  end
end
