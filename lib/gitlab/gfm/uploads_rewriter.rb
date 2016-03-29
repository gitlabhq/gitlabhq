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
        return unless @text

        new_uploader = file_uploader(target_project)
        @text.gsub(@pattern) do |markdown|
          file = find_file(@source_project, $~[:secret], $~[:file])
          return markdown unless file.try(:exists?)

          new_uploader.store!(file)
          new_uploader.to_h[:markdown]
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
        uploader = file_uploader(project, secret)
        uploader.retrieve_from_store!(file)
        uploader.file
      end

      def file_uploader(project, secret = nil)
        uploader = FileUploader.new(project, secret)
        uploader.define_singleton_method(:move_to_store) { false }
        uploader
      end
    end
  end
end
