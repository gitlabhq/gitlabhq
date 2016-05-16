module Gitlab
  module ImportExport
    class VersionRestorer

      def self.restore(*args)
        new(*args).restore
      end

      def initialize(shared:)
        @shared = shared
      end

      def restore
        version = File.open(version_file, &:readline)
        verify_version!(version)
      rescue => e
        @shared.error(e)
        false
      end

      private

      def version_file
        File.join(@shared.export_path, Gitlab::ImportExport.version_filename)
      end

      def verify_version!(version)
        if Gem::Version.new(version) > Gem::Version.new(Gitlab::ImportExport.VERSION)
          raise Gitlab::ImportExport::Error("Import version mismatch: Required <= #{Gitlab::ImportExport.VERSION} but was #{version}")
        else
          true
        end
      end
    end
  end
end

