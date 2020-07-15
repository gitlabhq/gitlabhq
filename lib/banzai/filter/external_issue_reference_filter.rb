# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that replaces external issue tracker references with links.
    # References are ignored if the project doesn't use an external issue
    # tracker.
    #
    # This filter does not support cross-project references.
    class ExternalIssueReferenceFilter < ReferenceFilter
      self.reference_type = :external_issue

      # Public: Find `JIRA-123` issue references in text
      #
      #   ExternalIssueReferenceFilter.references_in(text, pattern) do |match, issue|
      #     "<a href=...>##{issue}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match and the String issue reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text, pattern)
        text.gsub(pattern) do |match|
          yield match, $~[:issue]
        end
      end

      def call
        # Early return if the project isn't using an external tracker
        return doc if project.nil? || default_issues_tracker?

        ref_pattern = issue_reference_pattern
        ref_start_pattern = /\A#{ref_pattern}\z/

        nodes.each_with_index do |node, index|
          if text_node?(node)
            replace_text_when_pattern_matches(node, index, ref_pattern) do |content|
              issue_link_filter(content)
            end

          elsif element_node?(node)
            yield_valid_link(node) do |link, inner_html|
              if link =~ ref_start_pattern
                replace_link_node_with_href(node, index, link) do
                  issue_link_filter(link, link_content: inner_html)
                end
              end
            end
          end
        end

        doc
      end

      private

      # Replace `JIRA-123` issue references in text with links to the referenced
      # issue's details page.
      #
      # text - String text to replace references in.
      # link_content - Original content of the link being replaced.
      #
      # Returns a String with `JIRA-123` references replaced with links. All
      # links have `gfm` and `gfm-issue` class names attached for styling.
      def issue_link_filter(text, link_content: nil)
        self.class.references_in(text, issue_reference_pattern) do |match, id|
          url = url_for_issue(id)
          klass = reference_class(:issue)
          data  = data_attribute(project: project.id, external_issue: id)
          content = link_content || match

          %(<a href="#{url}" #{data}
               title="#{escape_once(issue_title)}"
               class="#{klass}">#{content}</a>)
        end
      end

      def url_for_issue(issue_id)
        return '' if project.nil?

        url = if only_path?
                project.external_issue_tracker.issue_path(issue_id)
              else
                project.external_issue_tracker.issue_url(issue_id)
              end

        # Ensure we return a valid URL to prevent possible XSS.
        URI.parse(url).to_s
      rescue URI::InvalidURIError
        ''
      end

      def default_issues_tracker?
        external_issues_cached(:default_issues_tracker?)
      end

      def issue_reference_pattern
        external_issues_cached(:external_issue_reference_pattern)
      end

      def project
        context[:project]
      end

      def issue_title
        "Issue in #{project.external_issue_tracker.title}"
      end

      def external_issues_cached(attribute)
        cached_attributes = Gitlab::SafeRequestStore[:banzai_external_issues_tracker_attributes] ||= Hash.new { |h, k| h[k] = {} }
        cached_attributes[project.id][attribute] = project.public_send(attribute) if cached_attributes[project.id][attribute].nil? # rubocop:disable GitlabSecurity/PublicSend
        cached_attributes[project.id][attribute]
      end
    end
  end
end
