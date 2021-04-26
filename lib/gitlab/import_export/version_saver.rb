# frozen_string_literal: true

module Gitlab
  module ImportExport
    class VersionSaver
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(shared:)
        @shared = shared
      end

      def save
        mkdir_p(@shared.export_path)

        File.write(version_file, Gitlab::ImportExport.version, mode: 'w')
        File.write(gitlab_version_file, Gitlab::VERSION, mode: 'w')
        File.write(gitlab_revision_file, Gitlab.revision, mode: 'w')
      rescue StandardError => e
        @shared.error(e)
        false
      end

      private

      def gitlab_version_file
        File.join(@shared.export_path, Gitlab::ImportExport.gitlab_version_filename)
      end

      def gitlab_revision_file
        File.join(@shared.export_path, Gitlab::ImportExport.gitlab_revision_filename)
      end

      def version_file
        File.join(@shared.export_path, Gitlab::ImportExport.version_filename)
      end
    end
  end
end
