# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    class ImportGistWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      GISTS_ERRORS_BY_ID = 'gitlab:github-gists-import:%{user_id}:errors'

      data_consistency :always
      queue_namespace  :github_gists_importer
      feature_category :importers

      sidekiq_options dead: false, retry: 5

      sidekiq_retries_exhausted do |msg|
        args = msg['args']
        user_id = args[0]
        gist_hash = args[1]
        jid = msg['jid']

        new.perform_failure(user_id, gist_hash, msg['error_class'], msg['error_message'], msg['correlation_id'])

        # If a job is being exhausted we still want to notify the
        # Gitlab::GithubGistsImport::FinishImportWorker to prevent
        # the entire import from getting stuck
        if args.length == 3 && (key = args.last) && key.is_a?(String)
          JobWaiter.notify(key, jid, ttl: Gitlab::Import::JOB_WAITER_TTL)
        end
      end

      def perform(user_id, gist_hash, notify_key)
        gist = representation_class.from_json_hash(gist_hash)
        github_identifiers = gist.github_identifiers

        with_logging(user_id, github_identifiers) do
          result = importer_class.new(gist, user_id).execute
          if result.success?
            track_gist_import('success', user_id)
          else
            error(user_id, result.errors, github_identifiers)

            perform_failure(
              user_id,
              gist_hash,
              importer_class::FileCountLimitError.name,
              importer_class::FILE_COUNT_LIMIT_MESSAGE
            )
          end

          JobWaiter.notify(notify_key, jid, ttl: Gitlab::Import::JOB_WAITER_TTL)
        end
      rescue StandardError => e
        log_and_track_error(user_id, e, github_identifiers)

        raise
      end

      def perform_failure(user_id, gist_hash, exception_class, exception_message, correlation_id = nil)
        track_gist_import('failed', user_id)

        github_identifiers = representation_class.from_json_hash(gist_hash).github_identifiers

        persist_failure(user_id, exception_class, exception_message, github_identifiers, correlation_id)
      end

      private

      def user(user_id)
        return @user if defined? @user

        @user ||= User.find(user_id)
      end

      def importer_class
        ::Gitlab::GithubGistsImport::Importer::GistImporter
      end

      def representation_class
        ::Gitlab::GithubGistsImport::Representation::Gist
      end

      def with_logging(user_id, github_identifiers)
        info(user_id, 'start importer', github_identifiers)

        yield

        info(user_id, 'importer finished', github_identifiers)
      end

      def track_gist_import(status, user_id)
        Gitlab::Tracking.event(
          self.class.name,
          'create',
          label: 'github_gist_import',
          user: user(user_id),
          status: status
        )
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
          external_identifiers: github_identifiers,
          message: 'importer failed',
          'exception.message': error_message
        }

        Gitlab::GithubImport::Logger.error(structured_payload(attributes))

        cache_error_for_email(user_id, github_identifiers[:id], error_message)
      end

      def info(user_id, message, gist_id)
        attributes = {
          user_id: user_id,
          message: message,
          external_identifiers: gist_id
        }

        Gitlab::GithubImport::Logger.info(structured_payload(attributes))
      end

      def cache_error_for_email(user_id, gist_id, error_message)
        key = format(GISTS_ERRORS_BY_ID, user_id: user_id)

        ::Gitlab::Cache::Import::Caching.hash_add(key, gist_id, error_message)
      end

      def persist_failure(user_id, exception_class, exception_message, github_identifiers, correlation_id = nil)
        ImportFailure.create!(
          source: importer_class.name,
          exception_class: exception_class,
          exception_message: exception_message.truncate(255),
          correlation_id_value: correlation_id || Labkit::Correlation::CorrelationId.current_or_new_id,
          user_id: user_id,
          organization_id: user(user_id).organizations.first.id,
          external_identifiers: github_identifiers
        )
      end
    end
  end
end
