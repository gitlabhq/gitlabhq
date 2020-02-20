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

        filter_signature_attachments(message).each do |attachment|
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

      private

      # If this is a signed message (e.g. S/MIME or PGP), remove the signature
      # from the uploaded attachments
      def filter_signature_attachments(message)
        attachments = message.attachments

        if message.content_type&.starts_with?('multipart/signed')
          signature_protocol = message.content_type_parameters[:protocol]

          attachments.delete_if { |attachment| attachment.content_type.starts_with?(signature_protocol) } if signature_protocol.present?
        end

        attachments
      end
    end
  end
end
