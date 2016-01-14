module Banzai
  module Filter
    # HTML filter that replaces snippet references with links. References to
    # snippets that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class SnippetReferenceFilter < AbstractReferenceFilter
      def self.object_class
        Snippet
      end

      def find_object(project, id)
        project.snippets.find_by(id: id)
      end

      def url_for_object(snippet, project)
        h = Gitlab::Application.routes.url_helpers
        h.namespace_project_snippet_url(project.namespace, project, snippet,
                                        only_path: context[:only_path])
      end
    end
  end
end
