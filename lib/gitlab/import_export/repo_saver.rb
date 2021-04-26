# frozen_string_literal: true

module Gitlab
  module ImportExport
    class RepoSaver
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :exportable, :shared

      def initialize(exportable:, shared:)
        @exportable = exportable
        @shared = shared
      end

      def save
        return true unless repository_exists? # it's ok to have no repo

        bundle_to_disk
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
