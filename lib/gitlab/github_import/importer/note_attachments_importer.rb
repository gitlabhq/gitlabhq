# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class NoteAttachmentsImporter
        attr_reader :note_text, :project, :client, :web_endpoint

        SUPPORTED_RECORD_TYPES = [::Release.name, ::Issue.name, ::MergeRequest.name, ::Note.name].freeze

        # note_text - An instance of `Gitlab::GithubImport::Representation::NoteText`.
        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(note_text, project, client)
          @note_text = note_text
          @project = project
          @client = client
          @web_endpoint = client.web_endpoint
        end

        def execute
          attachments = Gitlab::GithubImport::MarkdownText.fetch_attachments(note_text.text, web_endpoint)
          return if attachments.blank?

          new_text = attachments.reduce(note_text.text) do |text, attachment|
            new_url = gitlab_attachment_link(attachment)

            # we need to update video media file links with the correct markdown format
            if new_url.end_with?(*supported_video_media_types)
              text.gsub(attachment.url, "![media_attachment](#{new_url})")
            else
              text.gsub(attachment.url, new_url)
            end
          end

          update_note_record(new_text)
        end

        private

        def gitlab_attachment_link(attachment)
          project_import_source = project.import_source

          if attachment.part_of_project_blob?(project_import_source)
            convert_project_content_link(attachment.url, project_import_source)
          elsif attachment.media?(project_import_source) || attachment.doc_belongs_to_project?(project_import_source) ||
              attachment.user_attachment?
            download_attachment(attachment)
          else # url to other GitHub project
            attachment.url
          end
        end

        def supported_video_media_types
          @supported_video_media_types ||=
            ::Gitlab::GithubImport::AttachmentsDownloader::SUPPORTED_VIDEO_MEDIA_TYPES.map { |ext| ".#{ext}" }
        end

        # From: https://github.com/login/test-import-attachments-source/blob/main/example.md
        # To: https://gitlab.com/login/test-import-attachments-target/-/blob/main/example.md
        def convert_project_content_link(attachment_url, import_source)
          path_without_domain = attachment_url.gsub(web_endpoint, '')
          path_without_import_source = path_without_domain.gsub(import_source, '').delete_prefix('/')
          path_with_blob_prefix = "/-#{path_without_import_source}"

          ::Gitlab::Routing.url_helpers.project_url(project) + path_with_blob_prefix
        end

        # in: an instance of Gitlab::GithubImport::Markdown::Attachment
        # out: gitlab attachment markdown url
        def download_attachment(attachment)
          downloader = ::Gitlab::GithubImport::AttachmentsDownloader.new(attachment.url, options: options,
            web_endpoint: web_endpoint)

          file = downloader.perform

          # for ghe imports skip file attachments
          # in these cases the AttachmentsDownloader returns the redirect url
          # so we return the original attachment.url
          if web_endpoint != ::Octokit::Default.web_endpoint && file.is_a?(String) && file.starts_with?(github_file_url_regex) # rubocop:disable Layout/LineLength,Lint/RedundantCopDisableDirective -- minor infraction
            return attachment.url
          end

          # for ghe imports check on filetype to add ext to video attachments
          file = update_ghe_video_path(file) unless web_endpoint == ::Octokit::Default.web_endpoint

          uploader = UploadService.new(project, file, FileUploader).execute

          uploader.to_h[:url]
        end

        def options
          {
            headers: {
              'Authorization' => "Bearer #{client.octokit.access_token}"
            }
          }
        end

        def update_note_record(text)
          return unless supported_record_type?

          record = find_record
          column_name = record_column_for_type(note_text.record_type)

          record.update_column(column_name, text)
          record.refresh_markdown_cache!
        end

        def supported_record_type?
          SUPPORTED_RECORD_TYPES.include?(note_text.record_type)
        end

        def find_record
          record_class = note_text.record_type.constantize
          record_class.find(note_text.record_db_id)
        end

        def record_column_for_type(record_type)
          case record_type
          when ::Release.name, ::Issue.name, ::MergeRequest.name
            :description
          when ::Note.name
            :note
          end
        end

        def update_ghe_video_path(file)
          filepath = file.path
          return file if File.extname(filepath).present?

          mime_type = Marcel::MimeType.for(Pathname.new(filepath))
          return file unless mime_type.start_with?('video/')

          extension = case mime_type
                      when 'video/quicktime' then '.mov'
                      when 'video/mp4' then '.mp4'
                      when 'video/webm' then '.webm'
                      end

          return file if extension.blank?

          new_path = "#{filepath}.#{extension}"
          FileUtils.mv(filepath, new_path)
          File.open(new_path, 'rb')
        end

        def github_file_url_regex
          %r{#{Regexp.escape(web_endpoint)}/.*/files/}
        end
      end
    end
  end
end
