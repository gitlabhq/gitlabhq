# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces snippet references with links. References to
      # snippets that do not exist are ignored.
      #
      # This filter supports cross-project references.
      class SnippetReferenceFilter < AbstractReferenceFilter
        self.reference_type = :snippet
        self.object_class   = Snippet

        def parent_records(project, ids)
          return unless project.is_a?(Project)

          project.snippets.where(id: ids.to_a)
        end

        def find_object(project, id)
          reference_cache.records_per_parent[project][id]
        end

        def url_for_object(snippet, project)
          h = Gitlab::Routing.url_helpers
          h.project_snippet_url(project, snippet,
                                          only_path: context[:only_path])
        end
      end
    end
  end
end
