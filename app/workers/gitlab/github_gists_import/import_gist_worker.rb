# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    class ImportGistWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include Gitlab::NotifyUponDeath

      GISTS_ERRORS_BY_ID = 'gitlab:github-gists-import:%{user_id}:errors'

      data_consistency :always
      queue_namespace  :github_gists_importer
      feature_category :importers

      sidekiq_options dead: false, retry: 5

      sidekiq_retries_exhausted do |msg, _|
        new.track_gist_import('failed', msg['args'][0])
      end

      def perform(user_id, gist_hash, notify_key)
        gist = ::Gitlab::GithubGistsImport::Representation::Gist.from_json_hash(gist_hash)

        with_logging(user_id, gist.github_identifiers) do
          result = importer_class.new(gist, user_id).execute
          if result.success?
            track_gist_import('success', user_id)
          else
            error(user_id, result.errors, gist.github_identifiers)
            track_gist_import('failed', user_id)
          end

          JobWaiter.notify(notify_key, jid)
        end
      rescue StandardError => e
        log_and_track_error(user_id, e, gist.github_identifiers)

        raise
      end

      def track_gist_import(status, user_id)
        user = User.find(user_id)

        Gitlab::Tracking.event(
          self.class.name,
          'create',
          label: 'github_gist_import',
          user: user,
          status: status
        )
      end

      private

      def importer_class
        ::Gitlab::GithubGistsImport::Importer::GistImporter
      end

      def with_logging(user_id, github_identifiers)
        info(user_id, 'start importer', github_identifiers)

        yield

        info(user_id, 'importer finished', github_identifiers)
      end

      def log_and_track_error(user_id, exception, github_identifiers)
        error(user_id, exception.message, github_identifiers)

        Gitlab::ErrorTracking.track_exception(exception,
          import_type: :github_gists,
          user_id: user_id
        )
      end

      def error(user_id, error_message, github_identifiers)
        attributes = {
          user_id: user_id,
          github_identifiers: github_identifiers,
          message: 'importer failed',
          'error.message': error_message
        }

        Gitlab::GithubImport::Logger.error(structured_payload(attributes))

        cache_error_for_email(user_id, github_identifiers[:id], error_message)
      end

      def info(user_id, message, gist_id)
        attributes = {
          user_id: user_id,
          message: message,
          github_identifiers: gist_id
        }

        Gitlab::GithubImport::Logger.info(structured_payload(attributes))
      end

      def cache_error_for_email(user_id, gist_id, error_message)
        key = format(GISTS_ERRORS_BY_ID, user_id: user_id)

        ::Gitlab::Cache::Import::Caching.hash_add(key, gist_id, error_message)
      end
    end
  end
end
