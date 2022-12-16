# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    class FinishImportWorker
      include ApplicationWorker

      data_consistency :always
      queue_namespace :github_gists_importer
      feature_category :importers
      idempotent!

      sidekiq_options dead: false, retry: 5

      sidekiq_retries_exhausted do |msg, _|
        Gitlab::GithubGistsImport::Status.new(msg['args'][0]).fail!
      end

      INTERVAL = 30.seconds.to_i
      BLOCKING_WAIT_TIME = 5

      def perform(user_id, waiter_key, remaining)
        waiter = wait_for_jobs(waiter_key, remaining)

        if waiter.nil?
          Gitlab::GithubGistsImport::Status.new(user_id).finish!

          Gitlab::GithubImport::Logger.info(user_id: user_id, message: 'GitHub Gists import finished')
        else
          self.class.perform_in(INTERVAL, user_id, waiter.key, waiter.jobs_remaining)
        end
      end

      private

      def wait_for_jobs(key, remaining)
        waiter = JobWaiter.new(remaining, key)
        waiter.wait(BLOCKING_WAIT_TIME)

        return if waiter.jobs_remaining == 0

        waiter
      end
    end
  end
end
