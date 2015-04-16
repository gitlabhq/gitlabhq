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
        text.gsub(ISSUE_PATTERN) do |match|
          yield match, $~[:issue].to_i, $~[:project]
        end
      end

      # Pattern used to extract `#123` issue references from text
      #
      # This pattern supports cross-project references.
      ISSUE_PATTERN = /#{PROJECT_PATTERN}?\#(?<issue>([a-zA-Z\-]+-)?\d+)/

      def call
        replace_text_nodes_matching(ISSUE_PATTERN) do |content|
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
        self.class.references_in(text) do |match, issue, project_ref|
          project = self.project_from_ref(project_ref)

          if project && project.issue_exists?(issue)
            url = url_for_issue(issue, project, only_path: context[:only_path])

            title = escape_once("Issue: #{title_for_issue(issue, project)}")
            klass = reference_class(:issue)

            %(<a href="#{url}"
                 title="#{title}"
                 class="#{klass}">#{project_ref}##{issue}</a>)
          else
            match
          end
        end
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
