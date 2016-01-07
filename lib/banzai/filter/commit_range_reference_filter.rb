module Banzai
  module Filter
    # HTML filter that replaces commit range references with links.
    #
    # This filter supports cross-project references.
    class CommitRangeReferenceFilter < AbstractReferenceFilter
      def self.object_class
        CommitRange
      end

      def self.references_in(text, pattern = CommitRange.reference_pattern)
        text.gsub(pattern) do |match|
          yield match, $~[:commit_range], $~[:project], $~
        end
      end

      def self.referenced_by(node)
        project = Project.find(node.attr("data-project")) rescue nil
        return unless project

        id = node.attr("data-commit-range")
        range = find_object(project, id)

        return unless range

        { commit_range: range }
      end

      def initialize(*args)
        super

        @commit_map = {}
      end

      def self.find_object(project, id)
        range = CommitRange.new(id, project)

        range.valid_commits? ? range : nil
      end

      def find_object(*args)
        self.class.find_object(*args)
      end

      def url_for_object(range, project)
        h = Gitlab::Application.routes.url_helpers
        h.namespace_project_compare_url(project.namespace, project,
                                        range.to_param.merge(only_path: context[:only_path]))
      end

      def object_link_title(range)
        range.reference_title
      end
    end
  end
end
