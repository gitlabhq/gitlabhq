# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    class StartImportWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always
      queue_namespace :github_gists_importer
      feature_category :importers

      sidekiq_options dead: false, retry: 5

      worker_has_external_dependencies!

      sidekiq_retries_exhausted do |msg, _|
        Gitlab::GithubGistsImport::Status.new(msg['args'][0]).fail!

        user = User.find(msg['args'][0])
        Gitlab::Import::PageCounter.new(user, :gists, 'github-gists-importer').expire!
      end

      def perform(user_id, encrypted_token)
        logger.info(structured_payload(user_id: user_id, message: 'starting importer'))

        user = User.find(user_id)
        decrypted_token = Gitlab::CryptoHelper.aes256_gcm_decrypt(encrypted_token)
        result = Gitlab::GithubGistsImport::Importer::GistsImporter.new(user, decrypted_token).execute

        if result.success?
          schedule_finish_worker(user_id, result.waiter)
        elsif result.next_attempt_in
          schedule_next_attempt(result.next_attempt_in, user_id, encrypted_token)
        else
          log_error_and_raise!(user_id, result.error)
        end
      end

      private

      def schedule_finish_worker(user_id, waiter)
        logger.info(structured_payload(user_id: user_id, message: 'importer finished'))

        Gitlab::GithubGistsImport::FinishImportWorker.perform_async(user_id, waiter.key, waiter.jobs_remaining)
      end

      def schedule_next_attempt(next_attempt_in, user_id, encrypted_token)
        logger.info(structured_payload(user_id: user_id, message: 'rate limit reached'))

        self.class.perform_in(next_attempt_in, user_id, encrypted_token)
      end

      def log_error_and_raise!(user_id, error)
        logger.error(structured_payload(user_id: user_id, message: 'import failed', 'exception.message': error.message))

        raise(error)
      end

      def logger
        Gitlab::GithubImport::Logger
      end
    end
  end
end
