module Gitlab
  module ImportExport
    class VersionSaver

      def self.save(*args)
        new(*args).save
      end

      def initialize(shared:)
        @shared = shared
      end

      def save
        File.open(version_file, 'w') do |file|
          file.write(Gitlab::ImportExport.VERSION)
        end
      rescue => e
        @shared.error(e)
        false
      end

      private

      def version_file
        File.join(@shared.export_path, Gitlab::ImportExport.version_filename)
      end
    end
  end
end
