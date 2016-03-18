module Banzai
  module Filter
    # HTML filter that replaces external issue tracker references with links.
    # References are ignored if the project doesn't use an external issue
    # tracker.
    class ExternalIssueReferenceFilter < ReferenceFilter
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
        text.gsub(ExternalIssue.reference_pattern) do |match|
          yield match, $~[:issue]
        end
      end

      def self.referenced_by(node)
        project = Project.find(node.attr("data-project")) rescue nil
        return unless project

        id = node.attr("data-external-issue")
        external_issue = ExternalIssue.new(id, project)

        return unless external_issue

        { external_issue: external_issue }
      end

      def call
        # Early return if the project isn't using an external tracker
        return doc if project.nil? || project.default_issues_tracker?

        replace_text_nodes_matching(ExternalIssue.reference_pattern) do |content|
          issue_link_filter(content)
        end

        replace_link_nodes_with_href(ExternalIssue.reference_pattern) do |link, text|
          issue_link_filter(link, link_text: text)
        end
      end

      # Replace `JIRA-123` issue references in text with links to the referenced
      # issue's details page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `JIRA-123` references replaced with links. All
      # links have `gfm` and `gfm-issue` class names attached for styling.
      def issue_link_filter(text, link_text: nil)
        project = context[:project]

        self.class.references_in(text) do |match, id|
          ExternalIssue.new(id, project)

          url = url_for_issue(id, project, only_path: context[:only_path])

          title = "Issue in #{project.external_issue_tracker.title}"
          klass = reference_class(:issue)
          data  = data_attribute(project: project.id, external_issue: id)

          text = link_text || match

          %(<a href="#{url}" #{data}
               title="#{escape_once(title)}"
               class="#{klass}">#{escape_once(text)}</a>)
        end
      end

      def url_for_issue(*args)
        IssuesHelper.url_for_issue(*args)
      end
    end
  end
end
