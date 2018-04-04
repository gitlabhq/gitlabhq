module Banzai
  module Filter
    # HTML filter that replaces commit range references with links.
    #
    # This filter supports cross-project references.
    class CommitRangeReferenceFilter < AbstractReferenceFilter
      self.reference_type = :commit_range

      def self.object_class
        CommitRange
      end

      def self.references_in(text, pattern = CommitRange.reference_pattern)
        text.gsub(pattern) do |match|
          yield match, $~[:commit_range], $~[:project], $~[:namespace], $~
        end
      end

      def initialize(*args)
        super

        @commit_map = {}
      end

      def find_object(project, id)
        range = CommitRange.new(id, project)

        range.valid_commits? ? range : nil
      end

      def url_for_object(range, project)
        h = Gitlab::Routing.url_helpers
        h.project_compare_url(project,
                                        range.to_param.merge(only_path: context[:only_path]))
      end

      def object_link_title(range, matches)
        nil
      end
    end
  end
end
