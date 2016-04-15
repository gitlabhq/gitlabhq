module Gitlab
  module ImportExport
    class Importer
      include Gitlab::ImportExport::CommandLineUtil

      def self.import(*args)
        new(*args).import
      end

      def initialize(archive_file:, storage_path:)
        @archive_file = archive_file
        @storage_path = storage_path
      end

      def import
        decompress_export
      end

      private

      def decompress
        untar_czf(archive: archive_file, dir: @storage_path)
      end
    end
  end
end
