require 'html/pipeline'

module Gitlab
  module Markdown
    # HTML filter that replaces issue references with links. References within
    # <pre>, <code>, <a>, and <style> elements are ignored. References to issues
    # that do not exist are ignored.
    #
    # This filter supports cross-project references.
    #
    # Context options:
    #   :project (required) - Current project, ignored when reference is
    #                         cross-project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class IssueReferenceFilter < HTML::Pipeline::Filter
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
        text.gsub(ISSUE_PATTERN) do |match|
          yield match, $~[:issue].to_i, $~[:project]
        end
      end

      # Pattern used to extract `#123` issue references from text
      #
      # This pattern supports cross-project references.
      ISSUE_PATTERN = /#{PROJECT_PATTERN}?\#(?<issue>([a-zA-Z\-]+-)?\d+)/

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if project.nil?
          next unless project.default_issues_tracker?
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

      # Replace `#123` issue references in text with links to the referenced
      # issue's details page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `#123` references replaced with links. All links
      # have `gfm` and `gfm-issue` class names attached for styling.
      def issue_link_filter(text)
        self.class.references_in(text) do |match, issue, project_ref|
          project = self.project_from_ref(project_ref)

          if project.issue_exists?(issue)
            # FIXME: Ugly
            url = url_for_issue(issue, project, only_path: context[:only_path])

            title = "Issue: #{title_for_issue(issue, project)}"
            klass = "gfm gfm-issue #{context[:reference_class]}".strip

            %(<a href="#{url}"
                 title="#{title}"
                 class="#{klass}">#{project_ref}##{issue}</a>)
          else
            match
          end
        end
      end

      def project
        context[:project]
      end

      def url_for_issue(*args)
        IssuesHelper.url_for_issue(*args)
      end

      def title_for_issue(*args)
        IssuesHelper.title_for_issue(*args)
      end
    end
  end
end
