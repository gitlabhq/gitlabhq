# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class NoteAttachmentsImporter
        attr_reader :note_text, :project

        # note_text - An instance of `NoteText`.
        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(note_text, project, _client = nil)
          @note_text = note_text
          @project = project
        end

        def execute
          attachments = MarkdownText.fetch_attachments(note_text.text)
          return if attachments.blank?

          new_text = attachments.reduce(note_text.text) do |text, attachment|
            new_url = download_attachment(attachment)
            text.gsub(attachment.url, new_url)
          end

          update_note_record(new_text)
        end

        private

        # in: an instance of Gitlab::GithubImport::Markdown::Attachment
        # out: gitlab attachment markdown url
        def download_attachment(attachment)
          downloader = ::Gitlab::GithubImport::AttachmentsDownloader.new(attachment.url)
          file = downloader.perform
          uploader = UploadService.new(project, file, FileUploader).execute
          uploader.to_h[:url]
        ensure
          downloader&.delete
        end

        def update_note_record(text)
          case note_text.record_type
          when ::Release.name
            ::Release.find(note_text.record_db_id).update_column(:description, text)
          when ::Issue.name
            ::Issue.find(note_text.record_db_id).update_column(:description, text)
          when ::MergeRequest.name
            ::MergeRequest.find(note_text.record_db_id).update_column(:description, text)
          when ::Note.name
            ::Note.find(note_text.record_db_id).update_column(:note, text)
          end
        end
      end
    end
  end
end
