require 'fileutils'

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
          break markdown unless file.try(:exists?)

          new_uploader = FileUploader.new(target_project)
          with_link_in_tmp_dir(file.file) do |open_tmp_file|
            new_uploader.store!(open_tmp_file)
          end
          new_uploader.markdown_link
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
        uploader = FileUploader.new(project, secret: secret)
        uploader.retrieve_from_store!(file)
        uploader.file
      end

      # Because the uploaders use 'move_to_store' we must have a temporary
      # file that is allowed to be (re)moved.
      def with_link_in_tmp_dir(file)
        dir = Dir.mktmpdir('UploadsRewriter', File.dirname(file))
        # The filename matters to Carrierwave so we make sure to preserve it
        tmp_file = File.join(dir, File.basename(file))
        File.link(file, tmp_file)
        # Open the file to placate Carrierwave
        File.open(tmp_file) { |open_file| yield open_file }
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end
end
