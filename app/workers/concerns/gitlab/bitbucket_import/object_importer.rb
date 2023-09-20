# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    # ObjectImporter defines the base behaviour for every Sidekiq worker that
    # imports a single resource such as a note or pull request.
    module ObjectImporter
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker

        data_consistency :always

        feature_category :importers

        worker_has_external_dependencies!

        sidekiq_retries_exhausted do |msg|
          args = msg['args']
          jid = msg['jid']

          # If a job is being exhausted we still want to notify the
          # Gitlab::Import::AdvanceStageWorker to prevent the entire import from getting stuck
          key = args.last
          JobWaiter.notify(key, jid) if args.length == 3 && key && key.is_a?(String)
        end
      end

      def perform(project_id, hash, notify_key)
        project = Project.find_by_id(project_id)

        return unless project

        if project.import_state&.canceled?
          info(project.id, message: 'project import canceled')
          return
        end

        import(project, hash)
      ensure
        notify_waiter(notify_key)
      end

      private

      # project - An instance of `Project` to import the data into.
      # hash - A Hash containing the details of the object to import.
      def import(project, hash)
        info(project.id, message: 'importer started')

        importer_class.new(project, hash).execute

        info(project.id, message: 'importer finished')
      rescue ActiveRecord::RecordInvalid => e
        # We do not raise exception to prevent job retry
        track_exception(project, e)
      rescue StandardError => e
        track_and_raise_exception(project, e)
      end

      def notify_waiter(key)
        JobWaiter.notify(key, jid)
      end

      # Returns the class to use for importing the object.
      def importer_class
        raise NotImplementedError
      end

      def info(project_id, extra = {})
        Logger.info(log_attributes(project_id, extra))
      end

      def log_attributes(project_id, extra = {})
        extra.merge(
          project_id: project_id,
          importer: importer_class.name
        )
      end

      def track_exception(project, exception, fail_import: false)
        Gitlab::Import::ImportFailureService.track(
          project_id: project.id,
          error_source: importer_class.name,
          exception: exception,
          fail_import: fail_import
        )
      end

      def track_and_raise_exception(project, exception, fail_import: false)
        track_exception(project, exception, fail_import: fail_import)

        raise(exception)
      end
    end
  end
end
