module Banzai
  module Filter
    # HTML filter that replaces merge request references with links. References
    # to merge requests that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class MergeRequestReferenceFilter < IssuableReferenceFilter
      self.reference_type = :merge_request

      def self.object_class
        MergeRequest
      end

      def url_for_object(mr, project)
        h = Gitlab::Routing.url_helpers
        h.project_merge_request_url(project, mr,
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

      def parent_records(parent, ids)
        parent.merge_requests
          .where(iid: ids.to_a)
          .includes(target_project: :namespace)
      end
    end
  end
end
