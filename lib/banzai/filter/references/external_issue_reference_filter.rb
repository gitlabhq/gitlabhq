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

        def self.external_issues_cached(project, attribute)
          cached_attributes = Gitlab::SafeRequestStore[:banzai_external_issues_tracker_attributes] ||= Hash.new { |h, k| h[k] = {} }
          cached_attributes[project.id][attribute] = project.public_send(attribute) if cached_attributes[project.id][attribute].nil? # rubocop:disable GitlabSecurity/PublicSend
          cached_attributes[project.id][attribute]
        end

        def self.default_issues_tracker?(project)
          external_issues_cached(project, :default_issues_tracker?)
        end

        # Public: Find `JIRA-123` issue references in text
        #
        #   references_in(text, pattern) do |match_text, issue|
        #     "<a href=...>##{issue}</a>"
        #   end
        #
        # text - String text to search.
        #
        # Yields the String text match and the String issue reference.
        #
        # Returns a HTML String replaced with the return of the block.
        #
        # See ReferenceFilter#references_in for a detailed discussion.
        def references_in(text, pattern = object_reference_pattern)
          enumerator =
            case pattern
            when Regexp
              Gitlab::Utils::Gsub.gsub_with_limit(text, pattern, limit: Banzai::Filter::FILTER_ITEM_LIMIT)
            when Gitlab::UntrustedRegexp
              pattern.replace_gsub(text, limit: Banzai::Filter::FILTER_ITEM_LIMIT)
            else
              raise ArgumentError, "#{self.class.name} given #{pattern.class.name} pattern; should be Regexp or Gitlab::UntrustedRegexp"
            end

          replace_references_in_text_with_html(enumerator) do |match_data|
            yield match_data[0], match_data[:issue]
          end
        end

        def call
          # Early return if the project isn't using an external tracker
          return doc if project.nil? || self.class.default_issues_tracker?(project)

          super
        end

        private

        # Replace `JIRA-123` issue references in text with links to the referenced
        # issue's details page.
        #
        # text - String text to replace references in.
        # link_content_html - Original HTML content of the link being replaced.
        #
        # Returns a HTML String with `JIRA-123` references replaced with links. All
        # links have `gfm` and `gfm-issue` class names attached for styling.
        #
        # Returns nil if no replacements are made.
        def object_link_filter(text, pattern, link_content_html: nil, link_reference: false)
          references_in(text) do |match_text, id|
            klass = reference_class(:issue)
            data  = data_attribute(project: project.id, external_issue: id)
            content = link_content_html || CGI.escapeHTML(match_text)

            write_opening_tag("a", {
              "title" => issue_title,
              "class" => klass,
              **data
            }) << content.to_s << "</a>"
          end
        end

        def object_reference_pattern
          self.class.external_issues_cached(project, :external_issue_reference_pattern)
        end

        def issue_title
          "Issue in #{project.external_issue_tracker.title}"
        end

        # Called from PostProcessPipeline to add hrefs to anchors created above.
        #
        # We might be operating on cached HTML which already has hrefs;
        # replace them anyway, as they could be out of date.
        class LinkResolutionFilter < HTML::Pipeline::Filter
          def call
            # Early return if the project isn't using an external tracker
            return doc if project.nil? || ExternalIssueReferenceFilter.default_issues_tracker?(project)

            doc.xpath(query).each do |node|
              node["href"] = url_for_issue(node["data-external-issue"])
            end

            doc
          end

          def query
            @query ||= %{descendant-or-self::a[
              @data-reference-type="external_issue" and boolean(@data-external-issue)
            ]}
          end

          def project
            context[:project]
          end

          def url_for_issue(issue_id)
            url = if context[:only_path]
                    project.external_issue_tracker.issue_path(issue_id)
                  else
                    project.external_issue_tracker.issue_url(issue_id)
                  end

            # Ensure we return a valid URL to prevent possible XSS.
            URI.parse(url).to_s
          rescue URI::InvalidURIError
            ''
          end
        end
      end
    end
  end
end
