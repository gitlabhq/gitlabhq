# frozen_string_literal: true

require 'fileutils'

module Gitlab
  module Gfm
    ##
    # Class that rewrites markdown links for uploads
    #
    # Using a pattern defined in `FileUploader` it copies files to a new
    # project and rewrites all links to uploads in a given text.
    class UploadsRewriter
      include Gitlab::Utils::StrongMemoize

      def initialize(text, _text_html, source_container, _current_user)
        @text = text
        @source_container = source_container
        @pattern = FileUploader::MARKDOWN_PATTERN
      end

      def rewrite(target_container)
        return @text unless needs_rewrite?

        @target_container = target_container

        rewritten_text = Gitlab::StringRegexMarker.new(@text).mark(@pattern) do |markdown, left:, right:, mode:|
          transform_markdown(markdown)
        end

        # MarkdownContentRewriterService relies on the text being changed _in place_.
        @text.gsub!(@text, rewritten_text)
      end

      def needs_rewrite?
        strong_memoize(:needs_rewrite) do
          @pattern.match?(@text)
        end
      end

      private

      def was_embedded?(markdown)
        markdown.starts_with?("!")
      end

      def find_file(secret, file_name)
        UploaderFinder.new(@source_container, secret, file_name).execute
      end

      def transform_markdown(markdown)
        match = @pattern.match(markdown)
        file = find_file(match[:secret], match[:file])

        # No file will be returned for a path traversal
        return markdown unless file.try(:exists?)

        moved = uploader_class.copy_to(file, @target_container)
        moved_markdown = moved.markdown_link

        # Prevents rewrite of plain links as embedded
        if was_embedded?(markdown)
          moved_markdown
        else
          moved_markdown.delete_prefix('!')
        end
      end

      def uploader_class
        @klass ||= @target_container.is_a?(Group) ? NamespaceFileUploader : FileUploader
      end
    end
  end
end
