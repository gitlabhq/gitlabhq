module Banzai
  module Filter
    # HTML filter that replaces external issue tracker references with links.
    # References are ignored if the project doesn't use an external issue
    # tracker.
    class ExternalIssueReferenceFilter < ReferenceFilter
      self.reference_type = :external_issue

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

      def call
        # Early return if the project isn't using an external tracker
        return doc if project.nil? || default_issues_tracker?

        ref_pattern = ExternalIssue.reference_pattern
        ref_start_pattern = /\A#{ref_pattern}\z/

        each_node do |node|
          if text_node?(node)
            replace_text_when_pattern_matches(node, ref_pattern) do |content|
              issue_link_filter(content)
            end

          elsif element_node?(node)
            yield_valid_link(node) do |link, text|
              if link =~ ref_start_pattern
                replace_link_node_with_href(node, link) do
                  issue_link_filter(link, link_text: text)
                end
              end
            end
          end
        end

        doc
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

      def default_issues_tracker?
        if RequestStore.active?
          default_issues_tracker_cache[project.id] ||=
            project.default_issues_tracker?
        else
          project.default_issues_tracker?
        end
      end

      private

      def default_issues_tracker_cache
        RequestStore.store[:banzai_default_issues_tracker_cache] ||= {}
      end
    end
  end
end
