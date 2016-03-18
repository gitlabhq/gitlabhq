module Banzai
  module Filter
    # HTML filter that replaces commit references with links.
    #
    # This filter supports cross-project references.
    class CommitReferenceFilter < AbstractReferenceFilter
      def self.object_class
        Commit
      end

      def self.references_in(text, pattern = Commit.reference_pattern)
        text.gsub(pattern) do |match|
          yield match, $~[:commit], $~[:project], $~
        end
      end

      def self.referenced_by(node)
        project = Project.find(node.attr("data-project")) rescue nil
        return unless project

        id = node.attr("data-commit")
        commit = find_object(project, id)

        return unless commit

        { commit: commit }
      end

      def self.find_object(project, id)
        if project && project.valid_repo?
          project.commit(id)
        end
      end

      def find_object(*args)
        self.class.find_object(*args)
      end

      def url_for_object(commit, project)
        h = Gitlab::Application.routes.url_helpers
        h.namespace_project_commit_url(project.namespace, project, commit,
                                        only_path: context[:only_path])
      end

      def object_link_title(commit)
        commit.link_title
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
