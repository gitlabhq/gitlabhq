module Gitlab
  module ImportExport
    class FileImporter
      include Gitlab::ImportExport::CommandLineUtil

      def self.import(*args)
        new(*args).import
      end

      def initialize(archive_file:, shared:)
        @archive_file = archive_file
        @shared = shared
      end

      def import
        FileUtils.mkdir_p(@shared.export_path)
        decompress_archive
      rescue => e
        @shared.error(e)
        false
      end

      private

      def decompress_archive
        untar_zxf(archive: @archive_file, dir: @shared.export_path)
      end
    end
  end
end
