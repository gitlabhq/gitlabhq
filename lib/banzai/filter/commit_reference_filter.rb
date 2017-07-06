module Banzai
  module Filter
    # HTML filter that replaces commit references with links.
    #
    # This filter supports cross-project references.
    class CommitReferenceFilter < AbstractReferenceFilter
      self.reference_type = :commit

      def self.object_class
        Commit
      end

      def self.references_in(text, pattern = Commit.reference_pattern)
        text.gsub(pattern) do |match|
          yield match, $~[:commit], $~[:project], $~[:namespace], $~
        end
      end

      def find_object(project, id)
        if project && project.valid_repo?
          project.commit(id)
        end
      end

      def url_for_object(commit, project)
        h = Gitlab::Routing.url_helpers
        h.project_commit_url(project, commit,
                                        only_path: context[:only_path])
      end

      def object_link_text_extras(object, matches)
        extras = super

        path = matches[:path] if matches.names.include?("path")
        if path == '/builds'
          extras.unshift "builds"
        end

        extras
      end
    end
  end
end
