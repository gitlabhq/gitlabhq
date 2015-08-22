module Gitlab
  module Email
    class AttachmentUploader
      attr_accessor :message

      def initialize(message)
        @message = message
      end

      def execute(project)
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

            link = ::Projects::UploadService.new(project, file).execute
            attachments << link if link
          ensure
            tmp.close!
          end
        end

        attachments
      end
    end
  end
end
