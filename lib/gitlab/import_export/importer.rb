module Gitlab
  module ImportExport
    class Importer
      include Gitlab::ImportExport::CommandLineUtil

      def self.import(*args)
        new(*args).import
      end

      def initialize(archive_file: , storage_path:)
        @archive_file = archive_file
        @storage_path = storage_path
      end

      def import
        FileUtils.mkdir_p(@storage_path)
        decompress_archive
      end

      private

      def decompress_archive
        untar_czf(archive: @archive_file, dir: @storage_path)
      end
    end
  end
end
