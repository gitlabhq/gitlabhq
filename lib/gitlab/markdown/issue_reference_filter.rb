require 'gitlab/markdown'

module Gitlab
  module Markdown
    # HTML filter that replaces issue references with links. References to
    # issues that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class IssueReferenceFilter < ReferenceFilter
      include CrossProjectReference

      # Public: Find `#123` issue references in text
      #
      #   IssueReferenceFilter.references_in(text) do |match, issue, project_ref|
      #     "<a href=...>##{issue}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the Integer issue ID, and an optional String of
      # the external project reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(Issue.reference_pattern) do |match|
          yield match, $~[:issue].to_i, $~[:project]
        end
      end

      def self.referenced_by(node)
        { issue: LazyReference.new(Issue, node.attr("data-issue")) }
      end

      def call
        replace_text_nodes_matching(Issue.reference_pattern) do |content|
          issue_link_filter(content)
        end
      end

      # Replace `#123` issue references in text with links to the referenced
      # issue's details page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `#123` references replaced with links. All links
      # have `gfm` and `gfm-issue` class names attached for styling.
      def issue_link_filter(text)
        self.class.references_in(text) do |match, id, project_ref|
          project = self.project_from_ref(project_ref)

          if project && issue = project.get_issue(id)
            url = url_for_issue(id, project, only_path: context[:only_path])

            title = escape_once("Issue: #{issue.title}")
            klass = reference_class(:issue)
            data  = data_attribute(project: project.id, issue: issue.id)

            %(<a href="#{url}" #{data}
                 title="#{title}"
                 class="#{klass}">#{match}</a>)
          else
            match
          end
        end
      end

      def url_for_issue(*args)
        IssuesHelper.url_for_issue(*args)
      end
    end
  end
end
