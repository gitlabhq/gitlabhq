module Gitlab
  module ImportExport
    class WikiRestorer < RepoRestorer
      def initialize(project:, shared:, path_to_bundle:, wiki_enabled:)
        super(project: project, shared: shared, path_to_bundle: path_to_bundle)

        @wiki_enabled = wiki_enabled
      end

      def restore
        @project.wiki if create_empty_wiki?

        super
      end

      private

      def create_empty_wiki?
        !File.exist?(@path_to_bundle) && @wiki_enabled
      end
    end
  end
end
