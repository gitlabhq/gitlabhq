# frozen_string_literal: true

module Gitlab
  module Email
    class AttachmentUploader
      attr_accessor :message

      def initialize(message)
        @message = message
      end

      def execute(upload_parent:, uploader_class:, author: nil)
        attachments = []

        filter_signature_attachments(message).each do |attachment|
          tmp = Tempfile.new("gitlab-email-attachment")
          begin
            content = attachment.body.decoded
            File.open(tmp.path, "w+b") { |f| f.write content }
            sanitize_exif_if_needed(content, tmp.path)

            file = {
              tempfile: tmp,
              filename: attachment.filename,
              content_type: attachment.content_type
            }

            uploader = UploadService.new(
              upload_parent,
              file,
              uploader_class,
              uploaded_by_user_id: author&.id
            ).execute
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
        content_type = normalize_mime(message.content_type)
        protocol = normalize_mime(message.content_type_parameters&.fetch(:protocol, nil))

        if content_type == 'multipart/signed' && protocol
          attachments.delete_if { |attachment| protocol == normalize_mime(attachment.content_type) }
        end

        attachments
      end

      # normalizes mime-type ignoring case and removing extra data
      # also removes potential "x-" prefix from subtype, since some MUAs mix them
      # e.g. "application/x-pkcs7-signature" with "application/pkcs7-signature"
      def normalize_mime(content_type)
        MIME::Type.simplified(content_type, remove_x_prefix: true)
      end

      # https://gitlab.com/gitlab-org/gitlab/-/issues/239343
      def sanitize_exif_if_needed(content, path)
        exif_sanitizer = Gitlab::Sanitizers::Exif.new
        exif_sanitizer.clean_existing_path(path, content: content, skip_unallowed_types: true)
      end
    end
  end
end
