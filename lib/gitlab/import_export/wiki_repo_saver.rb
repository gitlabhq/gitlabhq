# frozen_string_literal: true

module Gitlab
  module ImportExport
    class WikiRepoSaver < RepoSaver
      def save
        wiki = ProjectWiki.new(project)
        @repository = wiki.repository

        super
      end

      private

      def bundle_full_path
        File.join(shared.export_path, ImportExport.wiki_repo_bundle_filename)
      end
    end
  end
end
