# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration takes all legacy uploads (that were uploaded using AttachmentUploader)
    # and migrate them to the new (FileUploader) location (=under projects).
    #
    # We have dependencies (uploaders) in this migration because extracting code would add a lot of complexity
    # and possible errors could appear as the logic in the uploaders is not trivial.
    #
    # This migration will be removed in 12.4 in order to get rid of a migration that depends on
    # the application code.
    class MigrateLegacyUploads
      include Database::MigrationHelpers
      include ::Gitlab::Utils::StrongMemoize

      # This class takes a legacy upload and migrates it to the correct location
      class UploadMover
        include Gitlab::Utils::StrongMemoize

        attr_reader :upload, :project, :note

        def initialize(upload)
          @upload = upload
          @note = Note.find_by(id: upload.model_id)
          @project = note&.project
        end

        def execute
          return unless upload

          if !project
            # if we don't have models associated with the upload we can not move it
            say "MigrateLegacyUploads: Deleting upload due to model not found: #{upload.inspect}"
            destroy_legacy_upload
          elsif note.is_a?(LegacyDiffNote)
            handle_legacy_note_upload
          elsif !legacy_file_exists?
            # if we can not find the file we just remove the upload record
            say "MigrateLegacyUploads: Deleting upload due to file not found: #{upload.inspect}"
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

          say "MigrateLegacyUploads: Copied file #{legacy_file_uploader.file.path} -> #{@uploader.file.path}"
          true
        rescue Exception => e
          say "MigrateLegacyUploads: File #{legacy_file_uploader.file.path} couldn't be copied to project uploads. Error: #{e.message}"
          false
        end
        # rubocop: enable Lint/RescueException

        def destroy_legacy_upload
          note.remove_attachment = true
          note.save

          if upload.destroy
            say "MigrateLegacyUploads: Upload #{upload.inspect} was destroyed."
          else
            say "MigrateLegacyUploads: Upload #{upload.inspect} destroy failed."
          end
        end

        def destroy_legacy_file
          legacy_file_uploader.file.delete
        end

        def add_upload_link_to_note_text
          new_text = "#{note.note} \n #{@uploader.markdown_link}"
          note.update!(
            note: new_text
          )
        end

        def legacy_file_uploader
          strong_memoize(:legacy_file_uploader) do
            uploader = upload.build_uploader
            uploader.retrieve_from_store!(File.basename(upload.path))
            uploader
          end
        end

        def legacy_file_exists?
          legacy_file_uploader.file.exists?
        end

        def handle_legacy_note_upload
          note.note += "\n \n Attachment ##{upload.id} with URL \"#{note.attachment.url}\" failed to migrate \
               for model class #{note.class}. See #{help_doc_link}."
          note.save

          say "MigrateLegacyUploads: LegacyDiffNote ##{note.id} found, can't move the file: #{upload.inspect} for upload ##{upload.id}. See #{help_doc_link}."
        end

        def say(message)
          Rails.logger.info(message)
        end

        def help_doc_link
          'https://docs.gitlab.com/ee/administration/troubleshooting/migrations.html#legacy-upload-migration'
        end
      end

      def perform(start_id, end_id)
        Upload.where(id: start_id..end_id, uploader: 'AttachmentUploader').find_each do |upload|
          UploadMover.new(upload).execute
        end
      end
    end
  end
end
