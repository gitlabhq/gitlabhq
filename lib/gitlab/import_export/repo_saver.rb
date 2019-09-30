# frozen_string_literal: true

module Gitlab
  module ImportExport
    class RepoSaver
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :project, :repository, :shared

      def initialize(project:, shared:)
        @project = project
        @shared = shared
        @repository = @project.repository
      end

      def save
        return true unless repository_exists? # it's ok to have no repo

        bundle_to_disk
      end

      private

      def repository_exists?
        repository.exists? && !repository.empty?
      end

      def bundle_full_path
        File.join(shared.export_path, ImportExport.project_bundle_filename)
      end

      def bundle_to_disk
        mkdir_p(shared.export_path)
        repository.bundle_to_disk(bundle_full_path)
      rescue => e
        shared.error(e)
        false
      end
    end
  end
end
