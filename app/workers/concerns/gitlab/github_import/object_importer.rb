# frozen_string_literal: true

module Gitlab
  module GithubImport
    # ObjectImporter defines the base behaviour for every Sidekiq worker that
    # imports a single resource such as a note or pull request.
    module ObjectImporter
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker

        include GithubImport::Queue
        include ReschedulingMethods

        feature_category :importers
        worker_has_external_dependencies!

        sidekiq_options retry: 5
        sidekiq_retries_exhausted do |msg|
          args = msg['args']
          jid = msg['jid']

          # If a job is being exhausted we still want to notify the
          # Gitlab::Import::AdvanceStageWorker to prevent the entire import from getting stuck
          if args.length == 3 && (key = args.last) && key.is_a?(String)
            JobWaiter.notify(key, jid, ttl: Gitlab::Import::JOB_WAITER_TTL)
          end
        end
      end

      NotRetriableError = Class.new(StandardError)

      # project - An instance of `Project` to import the data into.
      # client - An instance of `Gitlab::GithubImport::Client`
      # hash - A Hash containing the details of the object to import.
      def import(project, client, hash)
        if project.import_state&.completed?
          info(
            project.id,
            message: 'Project import is no longer running. Stopping worker.',
            import_status: project.import_state.status
          )

          return
        end

        object = representation_class.from_json_hash(hash)

        # To better express in the logs what object is being imported.
        self.github_identifiers = object.github_identifiers
        info(project.id, message: 'starting importer')

        importer_class.new(object, project, client).execute

        increment_object_counter(object, project) if increment_object_counter?(object)

        info(project.id, message: 'importer finished')
      rescue ActiveRecord::RecordInvalid, NotRetriableError, NoMethodError => e
        # We do not raise exception to prevent job retry
        track_exception(project, e)
      rescue UserFinder::FailedToObtainLockError
        warn(project.id, message: 'Failed to obtaing lock for user finder. Retrying later.')

        raise
      rescue StandardError => e
        track_and_raise_exception(project, e)
      end

      def increment_object_counter?(_object)
        true
      end

      def increment_object_counter(_object, project)
        Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :imported)
      end

      def object_type
        raise NotImplementedError
      end

      # Returns the representation class to use for the object. This class must
      # define the class method `from_json_hash`.
      def representation_class
        raise NotImplementedError
      end

      # Returns the class to use for importing the object.
      def importer_class
        raise NotImplementedError
      end

      private

      attr_accessor :github_identifiers

      def info(project_id, extra = {})
        Logger.info(log_attributes(project_id, extra))
      end

      def warn(project_id, extra = {})
        Logger.warn(log_attributes(project_id, extra))
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          project_id: project_id,
          importer: importer_class.name,
          external_identifiers: github_identifiers
        )
      end

      def track_exception(project, exception, fail_import: false)
        external_identifiers = github_identifiers || {}
        external_identifiers[:object_type] ||= object_type&.to_s

        Gitlab::Import::ImportFailureService.track(
          project_id: project.id,
          error_source: importer_class.name,
          exception: exception,
          fail_import: fail_import,
          external_identifiers: external_identifiers
        )
      end

      def track_and_raise_exception(project, exception, fail_import: false)
        track_exception(project, exception, fail_import: fail_import)

        raise(exception)
      end
    end
  end
end
