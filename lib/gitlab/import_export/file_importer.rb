module Gitlab
  module ImportExport
    class FileImporter
      include Gitlab::ImportExport::CommandLineUtil

      MAX_RETRIES = 8

      def self.import(*args)
        new(*args).import
      end

      def initialize(archive_file:, shared:)
        @archive_file = archive_file
        @shared = shared
      end

      def import
        mkdir_p(@shared.export_path)

        remove_symlinks!

        wait_for_archived_file do
          decompress_archive
        end
      rescue => e
        @shared.error(e)
        false
      ensure
        remove_symlinks!
      end

      private

      # Exponentially sleep until I/O finishes copying the file
      def wait_for_archived_file
        MAX_RETRIES.times do |retry_number|
          break if File.exist?(@archive_file)

          sleep(2**retry_number)
        end

        yield
      end

      def decompress_archive
        result = untar_zxf(archive: @archive_file, dir: @shared.export_path)

        raise Projects::ImportService::Error.new("Unable to decompress #{@archive_file} into #{@shared.export_path}") unless result

        result
      end

      def remove_symlinks!
        extracted_files.each do |path|
          FileUtils.rm(path) if File.lstat(path).symlink?
        end

        true
      end

      def extracted_files
        Dir.glob("#{@shared.export_path}/**/*", File::FNM_DOTMATCH).reject { |f| f =~ %r{.*/\.{1,2}$} }
      end
    end
  end
end
