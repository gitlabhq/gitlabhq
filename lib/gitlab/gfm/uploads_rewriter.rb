# frozen_string_literal: true

require 'fileutils'

module Gitlab
  module Gfm
    ##
    # Class that rewrites markdown links for uploads
    #
    # Using a pattern defined in `FileUploader` it copies files to a new
    # project and rewrites all links to uploads in a given text.
    #
    #
    class UploadsRewriter
      def initialize(text, source_project, _current_user)
        @text = text
        @source_project = source_project
        @pattern = FileUploader::MARKDOWN_PATTERN
      end

      def rewrite(target_parent)
        return @text unless needs_rewrite?

        @text.gsub(@pattern) do |markdown|
          file = find_file(@source_project, $~[:secret], $~[:file])
          break markdown unless file.try(:exists?)

          klass = target_parent.is_a?(Namespace) ? NamespaceFileUploader : FileUploader
          moved = klass.copy_to(file, target_parent)

          moved_markdown = moved.markdown_link

          # Prevents rewrite of plain links as embedded
          if was_embedded?(markdown)
            moved_markdown
          else
            moved_markdown.sub(/\A!/, "")
          end
        end
      end

      def needs_rewrite?
        files.any?
      end

      def files
        referenced_files = @text.scan(@pattern).map do
          find_file(@source_project, $~[:secret], $~[:file])
        end

        referenced_files.compact.select(&:exists?)
      end

      def was_embedded?(markdown)
        markdown.starts_with?("!")
      end

      private

      def find_file(project, secret, file)
        uploader = FileUploader.new(project, secret: secret)
        uploader.retrieve_from_store!(file)
        uploader
      end
    end
  end
end
