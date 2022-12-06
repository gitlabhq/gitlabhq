# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    class ImportGistWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include Gitlab::NotifyUponDeath

      data_consistency :always
      queue_namespace  :github_gists_importer
      feature_category :importers

      sidekiq_options dead: false, retry: 5

      def perform(user_id, gist_hash, notify_key)
        gist = ::Gitlab::GithubGistsImport::Representation::Gist.from_json_hash(gist_hash)

        with_logging(user_id, gist.github_identifiers) do
          result = importer_class.new(gist, user_id).execute
          error(user_id, result.errors, gist.github_identifiers) unless result.success?

          JobWaiter.notify(notify_key, jid)
        end
      rescue StandardError => e
        log_and_track_error(user_id, e, gist.github_identifiers)

        raise
      end

      private

      def importer_class
        ::Gitlab::GithubGistsImport::Importer::GistImporter
      end

      def with_logging(user_id, gist_id)
        info(user_id, 'start importer', gist_id)

        yield

        info(user_id, 'importer finished', gist_id)
      end

      def log_and_track_error(user_id, exception, gist_id)
        error(user_id, exception.message, gist_id)

        Gitlab::ErrorTracking.track_exception(exception,
          import_type: :github_gists,
          user_id: user_id
        )
      end

      def error(user_id, error_message, gist_id)
        attributes = {
          user_id: user_id,
          github_identifiers: gist_id,
          message: 'importer failed',
          'error.message': error_message
        }

        Gitlab::GithubImport::Logger.error(structured_payload(attributes))
      end

      def info(user_id, message, gist_id)
        attributes = {
          user_id: user_id,
          message: message,
          github_identifiers: gist_id
        }

        Gitlab::GithubImport::Logger.info(structured_payload(attributes))
      end
    end
  end
end
