module Gitlab
  module ImportExport
    class RepoSaver
      include Gitlab::ImportExport::CommandLineUtil

      attr_reader :full_path

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        return true if @project.empty_repo? # it's ok to have no repo

        @full_path = File.join(@shared.export_path, ImportExport.project_bundle_filename)
        bundle_to_disk
      end

      private

      def bundle_to_disk
        mkdir_p(@shared.export_path)
        @project.repository.bundle_to_disk(@full_path)
      rescue => e
        @shared.error(e)
        false
      end

      def path_to_repo
        @project.repository.path_to_repo
      end
    end
  end
end
