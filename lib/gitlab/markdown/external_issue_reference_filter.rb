require 'html/pipeline'

module Gitlab
  module Markdown
    # HTML filter that replaces external issue tracker references with links.
    # References within <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # Context options:
    #   :project (required) - Current project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class ExternalIssueReferenceFilter < HTML::Pipeline::Filter
      # Public: Find `JIRA-123` issue references in text
      #
      #   ExternalIssueReferenceFilter.references_in(text) do |match, issue|
      #     "<a href=...>##{issue}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match and the String issue reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(ISSUE_PATTERN) do |match|
          yield match, $~[:issue]
        end
      end

      # Pattern used to extract `JIRA-123` issue references from text
      ISSUE_PATTERN = /(?<issue>([A-Z\-]+-)\d+)/

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if project.nil?
          next if project.default_issues_tracker?
          next unless content.match(ISSUE_PATTERN)
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = issue_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      def validate
        needs :project
      end

      # Replace `JIRA-123` issue references in text with links to the referenced
      # issue's details page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `JIRA-123` references replaced with links. All
      # links have `gfm` and `gfm-issue` class names attached for styling.
      def issue_link_filter(text)
        project = context[:project]

        self.class.references_in(text) do |match, issue|
          url = url_for_issue(issue, project, only_path: context[:only_path])

          title = "Issue in #{project.external_issue_tracker.title}"
          klass = "gfm gfm-issue #{context[:reference_class]}".strip

          %(<a href="#{url}"
               title="#{title}"
               class="#{klass}">#{issue}</a>)
        end
      end

      # TODO (rspeicher): Duplicates IssueReferenceFilter
      def project
        context[:project]
      end

      # TODO (rspeicher): Duplicates IssueReferenceFilter
      def url_for_issue(*args)
        IssuesHelper.url_for_issue(*args)
      end
    end
  end
end
