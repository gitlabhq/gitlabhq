require 'html/pipeline'

module Gitlab
  module Markdown
    # HTML filter that replaces merge request references with links. References
    # within <pre>, <code>, <a>, and <style> elements are ignored. References to
    # merge requests that do not exist are ignored.
    #
    # This filter supports cross-project references.
    #
    # Context options:
    #   :project (required) - Current project, ignored when reference is
    #                         cross-project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class MergeRequestReferenceFilter < HTML::Pipeline::Filter
      include CrossProjectReference

      # Public: Find `!123` merge request references in text
      #
      #   MergeRequestReferenceFilter.references_in(text) do |match, merge_request, project_ref|
      #     "<a href=...>##{merge_request}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the Integer merge request ID, and an optional
      # String of the external project reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(MERGE_REQUEST_PATTERN) do |match|
          yield match, $~[:merge_request].to_i, $~[:project]
        end
      end

      # Pattern used to extract `!123` merge request references from text
      #
      # This pattern supports cross-project references.
      MERGE_REQUEST_PATTERN = /#{PROJECT_PATTERN}?!(?<merge_request>\d+)/

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if project.nil?
          next unless content.match(MERGE_REQUEST_PATTERN)
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = merge_request_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      def validate
        needs :project
      end

      # Replace `!123` merge request references in text with links to the
      # referenced merge request's details page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `!123` references replaced with links. All links
      # have `gfm` and `gfm-merge_request` class names attached for styling.
      def merge_request_link_filter(text)
        self.class.references_in(text) do |match, id, project_ref|
          project = self.project_from_ref(project_ref)

          if merge_request = project.merge_requests.find_by(iid: id)
            title = "Merge Request: #{merge_request.title}"
            klass = "gfm gfm-merge_request #{context[:reference_class]}".strip

            url = url_for_merge_request(merge_request, project)

            %(<a href="#{url}"
                 title="#{title}"
                 class="#{klass}">#{project_ref}!#{id}</a>)
          else
            match
          end
        end
      end

      def project
        context[:project]
      end

      # TODO (rspeicher): Cleanup
      def url_for_merge_request(mr, project)
        h = Rails.application.routes.url_helpers
        h.namespace_project_merge_request_url(project.namespace, project, mr,
                                            only_path: context[:only_path])
      end
    end
  end
end
