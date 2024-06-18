# frozen_string_literal: true

module Gitlab
  module ImportExport
    class VersionChecker
      def self.check!(*args, **kwargs)
        new(*args, **kwargs).check!
      end

      def initialize(shared:)
        @shared = shared
      end

      def check!
        version = File.open(version_file, &:readline)
        verify_version!(version)
      rescue StandardError => e
        @shared.error(e)
        false
      end

      private

      def version_file
        File.join(@shared.export_path, Gitlab::ImportExport.version_filename)
      end

      def verify_version!(version)
        if different_version?(version)
          raise Gitlab::ImportExport::Error, "Import version mismatch: Required #{Gitlab::ImportExport.version} but was #{version}"
        else
          true
        end
      end

      def different_version?(version)
        Gitlab::VersionInfo.parse(version) != Gitlab::VersionInfo.parse(Gitlab::ImportExport.version)
      rescue StandardError => e
        ::Import::Framework::Logger.error(
          message: 'Import error',
          error: e.message
        )

        raise Gitlab::ImportExport::Error, 'Incorrect VERSION format'
      end
    end
  end
end
