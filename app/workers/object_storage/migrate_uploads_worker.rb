# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker
module ObjectStorage
  class MigrateUploadsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include ObjectStorageQueue

    feature_category_not_owned!
    loggable_arguments 0, 1, 2, 3

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
    def self.enqueue!(uploads, model_class, mounted_as, to_store)
      sanity_check!(uploads, model_class, mounted_as)

      perform_async(uploads.ids, model_class.to_s, mounted_as, to_store)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # We need to be sure all the uploads are for the same uploader and model type
    # and that the mount point exists if provided.
    #
    def self.sanity_check!(uploads, model_class, mounted_as)
      upload = uploads.first
      uploader_class = upload.uploader.constantize
      uploader_types = uploads.map(&:uploader).uniq
      model_types = uploads.map(&:model_type).uniq
      model_has_mount = mounted_as.nil? || model_class.uploaders[mounted_as] == uploader_class

      raise(SanityCheckError, _("Multiple uploaders found: %{uploader_types}") % { uploader_types: uploader_types }) unless uploader_types.count == 1
      raise(SanityCheckError, _("Multiple model types found: %{model_types}") % { model_types: model_types }) unless model_types.count == 1
      raise(SanityCheckError, _("Mount point %{mounted_as} not found in %{model_class}.") % { mounted_as: mounted_as, model_class: model_class }) unless model_has_mount
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(*args)
      args_check!(args)

      (ids, model_type, mounted_as, to_store) = args

      @model_class = model_type.constantize
      @mounted_as = mounted_as&.to_sym
      @to_store = to_store

      uploads = Upload.preload(:model).where(id: ids)

      sanity_check!(uploads)
      results = migrate(uploads)

      report!(results)
    rescue SanityCheckError => e
      # do not retry: the job is insane
      Gitlab::AppLogger.warn "#{self.class}: Sanity check error (#{e.message})"
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def sanity_check!(uploads)
      self.class.sanity_check!(uploads, @model_class, @mounted_as)
    end

    def args_check!(args)
      return if args.count == 4

      case args.count
      when 3 then raise SanityCheckError, _("Job is missing the `model_type` argument.")
      else
        raise SanityCheckError, _("Job has wrong arguments format.")
      end
    end

    def build_uploaders(uploads)
      uploads.map { |upload| upload.retrieve_uploader(@mounted_as) }
    end

    def migrate(uploads)
      build_uploaders(uploads).map(&method(:process_uploader))
    end

    def process_uploader(uploader)
      MigrationResult.new(uploader.upload).tap do |result|
        uploader.migrate!(@to_store)
      rescue StandardError => e
        result.error = e
      end
    end
  end
end
# rubocop:enable Scalability/IdempotentWorker
