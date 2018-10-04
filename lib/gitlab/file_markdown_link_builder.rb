# Builds the markdown link of a file
# It needs the methods filename and secure_url (final destination url) to be defined.
module Gitlab
  module FileMarkdownLinkBuilder
    include FileTypeDetection

    def markdown_link
      return unless name = markdown_name

      markdown = "[#{name.gsub(']', '\\]')}](#{secure_url})"
      markdown.prepend("!") if image_or_video? || dangerous?
      markdown
    end

    def markdown_name
      return unless filename.present?

      image_or_video? ? File.basename(filename, File.extname(filename)) : filename
    end
  end
end
