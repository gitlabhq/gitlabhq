# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class GroupAvatarPipeline
        include Pipeline

        ALLOWED_AVATAR_DOWNLOAD_TYPES = (AvatarUploader::MIME_WHITELIST + %w(application/octet-stream)).freeze

        GroupAvatarLoadingError = Class.new(StandardError)

        def extract(context)
          context.extra[:tmpdir] = Dir.mktmpdir

          filepath = BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: "/groups/#{context.entity.encoded_source_full_path}/avatar",
            dir: context.extra[:tmpdir],
            file_size_limit: Avatarable::MAXIMUM_FILE_SIZE,
            allowed_content_types: ALLOWED_AVATAR_DOWNLOAD_TYPES
          ).execute

          BulkImports::Pipeline::ExtractedData.new(data: { filepath: filepath })
        end

        def load(context, data)
          return if data.blank?

          File.open(data[:filepath]) do |avatar|
            service = ::Groups::UpdateService.new(
              portable,
              current_user,
              avatar: avatar
            )

            unless service.execute
              raise GroupAvatarLoadingError, portable.errors.full_messages.first
            end
          end
        end

        def after_run(_)
          FileUtils.remove_entry(context.extra[:tmpdir]) if context.extra[:tmpdir].present?
        end
      end
    end
  end
end
