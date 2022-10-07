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
          attachment_urls = MarkdownText.fetch_attachment_urls(note_text.text)
          return if attachment_urls.blank?

          new_text = attachment_urls.reduce(note_text.text) do |text, url|
            new_url = download_attachment(url)
            text.gsub(url, new_url)
          end

          update_note_record(new_text)
        end

        private

        # in: github attachment markdown url
        # out: gitlab attachment markdown url
        def download_attachment(markdown_url)
          url = extract_url_from_markdown(markdown_url)
          name_prefix = extract_name_from_markdown(markdown_url)

          downloader = ::Gitlab::GithubImport::AttachmentsDownloader.new(url)
          file = downloader.perform
          uploader = UploadService.new(project, file, FileUploader).execute
          "#{name_prefix}(#{uploader.to_h[:url]})"
        ensure
          downloader&.delete
        end

        # in: "![image-icon](https://user-images.githubusercontent.com/..)"
        # out: https://user-images.githubusercontent.com/..
        def extract_url_from_markdown(text)
          text.match(%r{https://.*\)$}).to_a[0].chop
        end

        # in: "![image-icon](https://user-images.githubusercontent.com/..)"
        # out: ![image-icon]
        def extract_name_from_markdown(text)
          text.match(%r{^!?\[.*\]}).to_a[0]
        end

        def update_note_record(text)
          case note_text.record_type
          when ::Release.name
            ::Release.find(note_text.record_db_id).update_column(:description, text)
          when ::Note.name
            ::Note.find(note_text.record_db_id).update_column(:note, text)
          end
        end
      end
    end
  end
end
