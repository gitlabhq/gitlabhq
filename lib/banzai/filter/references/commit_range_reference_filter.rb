# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces commit range references with links.
      #
      # This filter supports cross-project references.
      class CommitRangeReferenceFilter < AbstractReferenceFilter
        self.reference_type = :commit_range
        self.object_class   = CommitRange

        def references_in(text, pattern = object_reference_pattern)
          text.gsub(pattern) do |match|
            yield match, $~[:commit_range], $~[:project], $~[:namespace], $~
          end
        end

        def initialize(*args)
          super

          @commit_map = {}
        end

        def find_object(project, id)
          return unless project.is_a?(Project)

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
end
