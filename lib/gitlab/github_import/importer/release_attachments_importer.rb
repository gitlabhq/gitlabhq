# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class ReleaseAttachmentsImporter
        attr_reader :release_db_id, :release_description, :project

        # release - An instance of `ReleaseAttachments`.
        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(release_attachments, project, _client = nil)
          @release_db_id = release_attachments.release_db_id
          @release_description = release_attachments.description
          @project = project
        end

        def execute
          attachment_urls = MarkdownText.fetch_attachment_urls(release_description)
          new_description = attachment_urls.reduce(release_description) do |description, url|
            new_url = download_attachment(url)
            description.gsub(url, new_url)
          end

          Release.find(release_db_id).update_column(:description, new_description)
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
      end
    end
  end
end
