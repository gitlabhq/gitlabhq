# frozen_string_literal: true

module Gitlab
  module Email
    class AttachmentUploader
      attr_accessor :message

      def initialize(message)
        @message = message
      end

      def execute(upload_parent:, uploader_class:)
        attachments = []

        message.attachments.each do |attachment|
          tmp = Tempfile.new("gitlab-email-attachment")
          begin
            File.open(tmp.path, "w+b") { |f| f.write attachment.body.decoded }

            file = {
              tempfile:     tmp,
              filename:     attachment.filename,
              content_type: attachment.content_type
            }

            uploader = UploadService.new(upload_parent, file, uploader_class).execute
            attachments << uploader.to_h if uploader
          ensure
            tmp.close!
          end
        end

        attachments
      end
    end
  end
end
