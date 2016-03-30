module Gitlab
  module Gfm
    ##
    # Class that rewrites markdown links for uploads
    #
    # Using a pattern defined in `FileUploader` it copies files to a new
    # project and rewrites all links to uploads in in a given text.
    #
    #
    class UploadsRewriter
      def initialize(text, source_project, _current_user)
        @text = text
        @source_project = source_project
        @pattern = FileUploader::MARKDOWN_PATTERN
      end

      def rewrite(target_project)
        return @text unless needs_rewrite?

        @text.gsub(@pattern) do |markdown|
          file = find_file(@source_project, $~[:secret], $~[:file])
          return markdown unless file.try(:exists?)

          new_uploader = FileUploader.new(target_project)
          new_uploader.store!(file)
          new_uploader.to_markdown
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

      private

      def find_file(project, secret, file)
        uploader = FileUploader.new(project, secret)
        uploader.retrieve_from_store!(file)
        uploader.file
      end
    end
  end
end
