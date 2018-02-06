# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
# rubocop:disable Style/Documentation

module ObjectStorage
  class MigrateUploadsWorker
    include ApplicationWorker
    include ObjectStorageQueue

    SanityCheckError = Class.new(StandardError)

    class Upload < ActiveRecord::Base
      # Upper limit for foreground checksum processing
      CHECKSUM_THRESHOLD = 100.megabytes

      belongs_to :model, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

      validates :size, presence: true
      validates :path, presence: true
      validates :model, presence: true
      validates :uploader, presence: true

      before_save  :calculate_checksum!, if: :foreground_checksummable?
      after_commit :schedule_checksum,   if: :checksummable?

      scope :stored_locally, -> { where(store: [nil, ObjectStorage::Store::LOCAL]) }
      scope :stored_remotely, -> { where(store: ObjectStorage::Store::REMOTE) }

      def self.hexdigest(path)
        Digest::SHA256.file(path).hexdigest
      end

      def absolute_path
        raise ObjectStorage::RemoteStoreError, "Remote object has no absolute path." unless local?
        return path unless relative_path?

        uploader_class.absolute_path(self)
      end

      def calculate_checksum!
        self.checksum = nil
        return unless checksummable?

        self.checksum = self.class.hexdigest(absolute_path)
      end

      def build_uploader(mounted_as = nil)
        uploader_class.new(model, mounted_as).tap do |uploader|
          uploader.upload = self
          uploader.retrieve_from_store!(identifier)
        end
      end

      def exist?
        File.exist?(absolute_path)
      end

      def local?
        return true if store.nil?

        store == ObjectStorage::Store::LOCAL
      end

      private

      def checksummable?
        checksum.nil? && local? && exist?
      end

      def foreground_checksummable?
        checksummable? && size <= CHECKSUM_THRESHOLD
      end

      def schedule_checksum
        UploadChecksumWorker.perform_async(id)
      end

      def relative_path?
        !path.start_with?('/')
      end

      def identifier
        File.basename(path)
      end

      def uploader_class
        Object.const_get(uploader)
      end
    end

    class MigrationResult
      attr_reader :upload
      attr_accessor :error

      def initialize(upload, error = nil)
        @upload, @error = upload, error
      end

      def success?
        error.nil?
      end

      def to_s
        success? ? "Migration successful." : "Error while migrating #{upload.id}: #{error.message}"
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

        Rails.logger.info header(success, failures)
        Rails.logger.warn failures(failures)

        raise MigrationFailures.new(failures.map(&:error)) if failures.any?
      end

      def header(success, failures)
        "Migrated #{success.count}/#{success.count + failures.count} files."
      end

      def failures(failures)
        failures.map { |f| "\t#{f}" }.join('\n')
      end
    end

    include Report

    def self.enqueue!(uploads, mounted_as, to_store)
      sanity_check!(uploads, mounted_as)

      perform_async(uploads.ids, mounted_as, to_store)
    end

    # We need to be sure all the uploads are for the same uploader and model type
    # and that the mount point exists if provided.
    #
    def self.sanity_check!(uploads, mounted_as)
      upload = uploads.first

      uploader_class = upload.uploader.constantize
      model_class = uploads.first.model_type.constantize

      uploader_types = uploads.map(&:uploader).uniq
      model_types = uploads.map(&:model_type).uniq
      model_has_mount = mounted_as.nil? || model_class.uploaders[mounted_as] == uploader_class

      raise(SanityCheckError, "Multiple uploaders found: #{uploader_types}") unless uploader_types.count == 1
      raise(SanityCheckError, "Multiple model types found: #{model_types}") unless model_types.count == 1
      raise(SanityCheckError, "Mount point #{mounted_as} not found in #{model_class}.") unless model_has_mount
    end

    def perform(ids, mounted_as, to_store)
      @mounted_as = mounted_as&.to_sym
      @to_store = to_store

      uploads = Upload.preload(:model).where(id: ids)

      sanity_check!(uploads)
      results = migrate(uploads)

      report!(results)
    rescue SanityCheckError => e
      # do not retry: the job is insane
      Rails.logger.warn "#{self.class}: Sanity check error (#{e.message})"
    end

    def sanity_check!(uploads)
      self.class.sanity_check!(uploads, @mounted_as)
    end

    def build_uploaders(uploads)
      uploads.map { |upload| upload.build_uploader(@mounted_as) }
    end

    def migrate(uploads)
      build_uploaders(uploads).map(&method(:process_uploader))
    end

    def process_uploader(uploader)
      MigrationResult.new(uploader.upload).tap do |result|
        begin
          uploader.migrate!(@to_store)
        rescue => e
          result.error = e
        end
      end
    end
  end
end
