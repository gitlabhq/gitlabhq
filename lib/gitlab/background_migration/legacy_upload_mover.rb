# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class takes a legacy upload and migrates it to the correct location
    class LegacyUploadMover
      include Gitlab::Utils::StrongMemoize

      attr_reader :upload, :project, :note
      attr_accessor :logger

      def initialize(upload)
        @upload = upload
        @note = Note.find_by(id: upload.model_id)
        @project = note&.project
        @logger = Gitlab::BackgroundMigration::Logger.build
      end

      def execute
        return unless upload
        return unless upload.model_type == 'Note'

        if !project
          # if we don't have models associated with the upload we can not move it
          warn('Deleting upload due to model not found.')

          destroy_legacy_upload
        elsif note.is_a?(LegacyDiffNote)
          return unless move_legacy_diff_file

          migrate_upload
        elsif !legacy_file_exists?
          warn('Deleting upload due to file not found.')
          destroy_legacy_upload
        else
          migrate_upload
        end
      end

      private

      def migrate_upload
        return unless copy_upload_to_project

        add_upload_link_to_note_text
        destroy_legacy_file
        destroy_legacy_upload
      end

      # we should proceed and log whenever one upload copy fails, no matter the reasons
      # rubocop: disable Lint/RescueException
      def copy_upload_to_project
        @uploader = FileUploader.copy_to(legacy_file_uploader, project)

        logger.info(
          message: 'MigrateLegacyUploads: File copied successfully',
          old_path: legacy_file_uploader.file.path, new_path: @uploader.file.path
        )
        true
      rescue Exception => e
        warn(
          'File could not be copied to project uploads',
          file_path: legacy_file_uploader.file.path, error: e.message
        )
        false
      end
      # rubocop: enable Lint/RescueException

      def destroy_legacy_upload
        if note
          note.remove_attachment = true
          note.save
        end

        if upload.destroy
          logger.info(message: 'MigrateLegacyUploads: Upload was destroyed.', upload: upload.inspect)
        else
          warn('MigrateLegacyUploads: Upload destroy failed.')
        end
      end

      def destroy_legacy_file
        legacy_file_uploader.file.delete
      end

      def add_upload_link_to_note_text
        new_text = "#{note.note} \n #{@uploader.markdown_link}"
        # Bypass validations because old data may have invalid
        # noteable values. If we fail hard here, we may kill the
        # entire background migration, which affects a range of notes.
        note.update_attribute(:note, new_text)
      end

      def legacy_file_uploader
        strong_memoize(:legacy_file_uploader) do
          uploader = upload.retrieve_uploader
          uploader.retrieve_from_store!(File.basename(upload.path))
          uploader
        end
      end

      def legacy_file_exists?
        legacy_file_uploader.file.exists?
      end

      # we should proceed and log whenever one upload copy fails, no matter the reasons
      # rubocop: disable Lint/RescueException
      def move_legacy_diff_file
        old_path = upload.absolute_path
        old_path_sub = '-/system/note/attachment'

        if !File.exist?(old_path) || old_path.exclude?(old_path_sub)
          log_legacy_diff_note_problem(old_path)
          return false
        end

        new_path = upload.absolute_path.sub(old_path_sub, '-/system/legacy_diff_note/attachment')
        new_dir = File.dirname(new_path)
        FileUtils.mkdir_p(new_dir)

        FileUtils.mv(old_path, new_path)
      rescue Exception => e
        log_legacy_diff_note_problem(old_path, new_path, e)
        false
      end

      def warn(message, params = {})
        logger.warn(
          params.merge(message: "MigrateLegacyUploads: #{message}", upload: upload.inspect)
        )
      end

      def log_legacy_diff_note_problem(old_path, new_path = nil, error = nil)
        warn('LegacyDiffNote upload could not be moved to a new path',
          old_path: old_path, new_path: new_path, error: error&.message
        )
      end
      # rubocop: enable Lint/RescueException
    end
  end
end
