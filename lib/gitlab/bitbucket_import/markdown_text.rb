# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class MarkdownText
      class << self
        # No web_endpoint argument (unlike the GitHub importer): Bitbucket Cloud uses fixed hosts
        # (see Markdown::Attachment::BITBUCKET_MEDIA_HOSTS), so there is no per-instance URL to pass.
        def fetch_attachments(text)
          attachments = []
          return attachments if text.nil?

          doc = CommonMarker.render_doc(text)

          doc.walk do |node|
            attachment = extract_attachment(node)
            attachments << attachment if attachment
          end
          attachments
        end

        private

        def extract_attachment(node)
          ::Gitlab::BitbucketImport::Markdown::Attachment.from_markdown(node)
        end
      end
    end
  end
end
