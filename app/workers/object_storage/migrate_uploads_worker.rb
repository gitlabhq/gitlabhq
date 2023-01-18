# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker
module ObjectStorage
  class MigrateUploadsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include ObjectStorageQueue

    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
    loggable_arguments 0

    SanityCheckError = Class.new(StandardError)

    class MigrationResult
      attr_reader :upload
      attr_accessor :error

      def initialize(upload, error = nil)
        @upload = upload
        @error = error
      end

      def success?
        error.nil?
      end

      def to_s
        success? ? _("Migration successful.") : _("Error while migrating %{upload_id}: %{error_message}") % { upload_id: upload.id, error_message: error.message }
      end
    end

    module Report
      class MigrationFailures < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
        end

        def message
          errors.map(&:message).join("\n")
        end
      end

      def report!(results)
        success, failures = results.partition(&:success?)

        Gitlab::AppLogger.info header(success, failures)
        Gitlab::AppLogger.warn failures(failures)

        raise MigrationFailures, failures.map(&:error) if failures.any?
      end

      def header(success, failures)
        _("Migrated %{success_count}/%{total_count} files.") % { success_count: success.count, total_count: success.count + failures.count }
      end

      def failures(failures)
        failures.map { |f| "\t#{f}" }.join('\n')
      end
    end

    include Report

    # rubocop: disable CodeReuse/ActiveRecord
    def self.enqueue!(uploads, to_store)
      perform_async(uploads.ids, to_store)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(*args)
      ids, to_store = retrieve_applicable_args!(args)

      @to_store = to_store

      uploads = Upload.preload(:model).where(id: ids)

      results = migrate(uploads)

      report!(results)
    rescue SanityCheckError => e
      # do not retry: the job is insane
      Gitlab::AppLogger.warn "#{self.class}: Sanity check error (#{e.message})"
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def retrieve_applicable_args!(args)
      return args if args.count == 2
      return args.values_at(0, 3) if args.count == 4

      raise SanityCheckError, _("Job has wrong arguments format.")
    end

    def migrate(uploads)
      uploads.map { |upload| process_upload(upload) }
    end

    def process_upload(upload)
      MigrationResult.new(upload).tap do |result|
        upload.retrieve_uploader.migrate!(@to_store)
      rescue StandardError => e
        result.error = e
      end
    end
  end
end
# rubocop:enable Scalability/IdempotentWorker
