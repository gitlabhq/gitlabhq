module Banzai
  module Filter
    # HTML filter that replaces merge request references with links. References
    # to merge requests that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class MergeRequestReferenceFilter < AbstractReferenceFilter
      def self.object_class
        MergeRequest
      end

      def find_object(project, id)
        project.merge_requests.find_by(iid: id)
      end

      def url_for_object(mr, project)
        h = Gitlab::Application.routes.url_helpers
        h.namespace_project_merge_request_url(project.namespace, project, mr,
                                            only_path: context[:only_path])
      end

      def object_link_text_extras(object, matches)
        extras = super

        path = matches[:path] if matches.names.include?("path")
        case path
        when '/diffs'
          extras.unshift "diffs"
        when '/commits'
          extras.unshift "commits"
        when '/builds'
          extras.unshift "builds"
        end

        extras
      end
    end
  end
end
