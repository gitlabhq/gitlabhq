# frozen_string_literal: true

module Gitlab
  module Uploads
    class MigrationHelper
      attr_reader :logger

      def initialize(args, logger)
        prepare_variables(args, logger)
      end

      def migrate_to_remote_storage
        @to_store = ObjectStorage::Store::REMOTE

        uploads.each_batch(of: batch_size, &method(:enqueue_batch))
      end

      def migrate_to_local_storage
        @to_store = ObjectStorage::Store::LOCAL

        uploads(ObjectStorage::Store::REMOTE).each_batch(of: batch_size, &method(:enqueue_batch))
      end

      private

      def batch_size
        ENV.fetch('MIGRATION_BATCH_SIZE', 200).to_i
      end

      def prepare_variables(args, logger)
        @mounted_as     = args.mounted_as&.delete(':')
        @uploader_class = args.uploader_class
        @model_class    = args.model_class&.constantize
        @logger         = logger
      end

      def enqueue_batch(batch, index)
        job = ObjectStorage::MigrateUploadsWorker.enqueue!(batch, @to_store)
        logger.info(message: "[Uploads migration] Enqueued upload migration job", index: index, job_id: job)
      rescue ObjectStorage::MigrateUploadsWorker::SanityCheckError => e
        # continue for the next batch
        logger.warn(message: "[Uploads migration] Could not enqueue batch", ids: batch.ids, reason: e.message) # rubocop:disable CodeReuse/ActiveRecord
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def uploads(store_type = [nil, ObjectStorage::Store::LOCAL])
        Upload.class_eval { include EachBatch } unless Upload < EachBatch

        uploads = Upload.where(store: store_type)
        uploads = uploads.where(uploader: @uploader_class) if @uploader_class.present?
        uploads = uploads.where(model_type: @model_class.base_class.sti_name) if @model_class.present?
        uploads = uploads.where(mount_point: @mounted_as) if @mounted_as.present?

        uploads
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end

Gitlab::Uploads::MigrationHelper.prepend_mod_with('Gitlab::Uploads::MigrationHelper')
