require 'gitlab/markdown'

module Gitlab
  module Markdown
    # HTML filter that replaces commit range references with links.
    #
    # This filter supports cross-project references.
    class CommitRangeReferenceFilter < ReferenceFilter
      include CrossProjectReference

      # Public: Find commit range references in text
      #
      #   CommitRangeReferenceFilter.references_in(text) do |match, commit_range, project_ref|
      #     "<a href=...>#{commit_range}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the String commit range, and an optional String
      # of the external project reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(CommitRange.reference_pattern) do |match|
          yield match, $~[:commit_range], $~[:project]
        end
      end

      def initialize(*args)
        super

        @commit_map = {}
      end

      def call
        replace_text_nodes_matching(CommitRange.reference_pattern) do |content|
          commit_range_link_filter(content)
        end
      end

      # Replace commit range references in text with links to compare the commit
      # ranges.
      #
      # text - String text to replace references in.
      #
      # Returns a String with commit range references replaced with links. All
      # links have `gfm` and `gfm-commit_range` class names attached for
      # styling.
      def commit_range_link_filter(text)
        self.class.references_in(text) do |match, id, project_ref|
          project = self.project_from_ref(project_ref)

          range = CommitRange.new(id, project)

          if range.valid_commits?
            push_result(:commit_range, range)

            url = url_for_commit_range(project, range)

            title = range.reference_title
            klass = reference_class(:commit_range)
            data  = data_attribute(project.id)

            project_ref += '@' if project_ref

            %(<a href="#{url}" #{data}
                 title="#{title}"
                 class="#{klass}">#{project_ref}#{range}</a>)
          else
            match
          end
        end
      end

      def url_for_commit_range(project, range)
        h = Gitlab::Application.routes.url_helpers
        h.namespace_project_compare_url(project.namespace, project,
                                        range.to_param.merge(only_path: context[:only_path]))
      end
    end
  end
end
