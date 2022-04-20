# frozen_string_literal: true

module Gitlab
  module ImportExport
    class RepoSaver
      include Gitlab::ImportExport::CommandLineUtil
      include DurationMeasuring

      attr_reader :exportable, :shared

      def initialize(exportable:, shared:)
        @exportable = exportable
        @shared = shared
      end

      def save
        with_duration_measuring do
          # it's ok to have no repo
          break true unless repository_exists?

          bundle_to_disk
        end
      end

      def repository
        @repository ||= @exportable.repository
      end

      private

      def repository_exists?
        repository.exists? && !repository.empty?
      end

      def bundle_full_path
        File.join(shared.export_path, bundle_filename)
      end

      def bundle_filename
        ::Gitlab::ImportExport.project_bundle_filename
      end

      def bundle_to_disk
        mkdir_p(File.dirname(bundle_full_path))

        repository.bundle_to_disk(bundle_full_path)
      rescue StandardError => e
        shared.error(e)
        false
      end
    end
  end
end
