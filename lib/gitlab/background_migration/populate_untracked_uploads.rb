# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class processes a batch of rows in `untracked_files_for_uploads` by
    # adding each file to the `uploads` table if it does not exist.
    class PopulateUntrackedUploads # rubocop:disable Metrics/ClassLength
      def perform(start_id, end_id)
        return unless migrate?

        files = Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::UntrackedFile.where(id: start_id..end_id)
        processed_files = insert_uploads_if_needed(files)
        processed_files.delete_all

        drop_temp_table_if_finished
      end

      private

      def migrate?
        Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::UntrackedFile.table_exists? &&
          Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::Upload.table_exists?
      end

      def insert_uploads_if_needed(files)
        filtered_files, error_files = filter_error_files(files)
        filtered_files = filter_existing_uploads(filtered_files)
        filtered_files = filter_deleted_models(filtered_files)
        insert(filtered_files)

        processed_files = files.where.not(id: error_files.map(&:id))
        processed_files
      end

      def filter_error_files(files)
        files.partition do |file|
          begin
            file.to_h
            true
          rescue => e
            msg = <<~MSG
              Error parsing path "#{file.path}":
                #{e.message}
                #{e.backtrace.join("\n  ")}
            MSG
            Rails.logger.error(msg)
            false
          end
        end
      end

      def filter_existing_uploads(files)
        paths = files.map(&:upload_path)
        existing_paths = Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::Upload.where(path: paths).pluck(:path).to_set

        files.reject do |file|
          existing_paths.include?(file.upload_path)
        end
      end

      # There are files on disk that are not in the uploads table because their
      # model was deleted, and we don't delete the files on disk.
      def filter_deleted_models(files)
        ids = deleted_model_ids(files)

        files.reject do |file|
          ids[file.model_type].include?(file.model_id)
        end
      end

      def deleted_model_ids(files)
        ids = {
          'Appearance' => [],
          'Namespace' => [],
          'Note' => [],
          'Project' => [],
          'User' => []
        }

        # group model IDs by model type
        files.each do |file|
          ids[file.model_type] << file.model_id
        end

        ids.each do |model_type, model_ids|
          model_class = "Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::#{model_type}".constantize
          found_ids = model_class.where(id: model_ids.uniq).pluck(:id)
          deleted_ids = ids[model_type] - found_ids
          ids[model_type] = deleted_ids
        end

        ids
      end

      def insert(files)
        rows = files.map do |file|
          file.to_h.merge(created_at: 'NOW()')
        end

        Gitlab::Database.bulk_insert('uploads',
                                     rows,
                                     disable_quote: :created_at)
      end

      def drop_temp_table_if_finished
        if Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::UntrackedFile.all.empty? && !Rails.env.test? # Dropping a table intermittently breaks test cleanup
          Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::UntrackedFile.connection.drop_table(:untracked_files_for_uploads,
                                              if_exists: true)
        end
      end
    end
  end
end
