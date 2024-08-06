# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces external issue tracker references with links.
      # References are ignored if the project doesn't use an external issue
      # tracker.
      #
      # This filter does not support cross-project references.
      class ExternalIssueReferenceFilter < ReferenceFilter
        self.reference_type = :external_issue
        self.object_class   = ExternalIssue

        # Public: Find `JIRA-123` issue references in text
        #
        #   references_in(text, pattern) do |match, issue|
        #     "<a href=...>##{issue}</a>"
        #   end
        #
        # text - String text to search.
        #
        # Yields the String match and the String issue reference.
        #
        # Returns a String replaced with the return of the block.
        def references_in(text, pattern = object_reference_pattern)
          case pattern
          when Regexp
            Gitlab::Utils::Gsub.gsub_with_limit(text, pattern, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match_data|
              yield match_data[0], match_data[:issue]
            end
          when Gitlab::UntrustedRegexp
            pattern.replace_gsub(text, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match|
              yield match, match[:issue]
            end
          end
        end

        def call
          # Early return if the project isn't using an external tracker
          return doc if project.nil? || default_issues_tracker?

          super
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
        def object_link_filter(text, pattern, link_content: nil, link_reference: false)
          references_in(text) do |match, id|
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

        def object_reference_pattern
          external_issues_cached(:external_issue_reference_pattern)
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
end
