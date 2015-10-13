require 'gitlab/markdown'

module Gitlab
  module Markdown
    # HTML filter that replaces merge request references with links. References
    # to merge requests that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class MergeRequestReferenceFilter < ReferenceFilter
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
        text.gsub(MergeRequest.reference_pattern) do |match|
          yield match, $~[:merge_request].to_i, $~[:project]
        end
      end

      def self.referenced_by(node)
        { merge_request: LazyReference.new(MergeRequest, node.attr("data-merge-request")) }
      end

      def call
        replace_text_nodes_matching(MergeRequest.reference_pattern) do |content|
          merge_request_link_filter(content)
        end
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

          if project && merge_request = project.merge_requests.find_by(iid: id)
            title = escape_once("Merge Request: #{merge_request.title}")
            klass = reference_class(:merge_request)
            data  = data_attribute(project: project.id, merge_request: merge_request.id)

            url = url_for_merge_request(merge_request, project)

            %(<a href="#{url}" #{data}
                 title="#{title}"
                 class="#{klass}">#{match}</a>)
          else
            match
          end
        end
      end

      def url_for_merge_request(mr, project)
        h = Gitlab::Application.routes.url_helpers
        h.namespace_project_merge_request_url(project.namespace, project, mr,
                                            only_path: context[:only_path])
      end
    end
  end
end
