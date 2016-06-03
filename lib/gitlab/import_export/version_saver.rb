module Gitlab
  module ImportExport
    class VersionSaver

      def initialize(shared:)
        @shared = shared
      end

      def save
        FileUtils.mkdir_p(@shared.export_path)

        File.open(version_file, 'w') do |file|
          file.write(Gitlab::ImportExport.version)
        end
      rescue => e
        @shared.error(e.message)
        false
      end

      private

      def version_file
        File.join(@shared.export_path, Gitlab::ImportExport.version_filename)
      end
    end
  end
end
