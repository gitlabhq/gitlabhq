# frozen_string_literal: true

module Gitlab
  module ImportExport
    class DesignRepoSaver < RepoSaver
      def save
        @repository = project.design_repository

        super
      end

      private

      def bundle_full_path
        File.join(shared.export_path, ::Gitlab::ImportExport.design_repo_bundle_filename)
      end
    end
  end
end
