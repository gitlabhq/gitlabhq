module Banzai
  module Filter
    # HTML filter that replaces merge request references with links. References
    # to merge requests that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class MergeRequestReferenceFilter < AbstractReferenceFilter
      self.reference_type = :merge_request

      def self.object_class
        MergeRequest
      end

      def find_object(project, iid)
        merge_requests_per_project[project][iid]
      end

      def url_for_object(mr, project)
        h = Gitlab::Routing.url_helpers
        h.project_merge_request_url(project, mr,
                                            only_path: context[:only_path])
      end

      def project_from_ref(ref)
        projects_per_reference[ref || current_project_path]
      end

      # Returns a Hash containing the merge_requests per Project instance.
      def merge_requests_per_project
        @merge_requests_per_project ||= begin
          hash = Hash.new { |h, k| h[k] = {} }

          projects_per_reference.each do |path, project|
            merge_request_ids = references_per_project[path]

            merge_requests = project.merge_requests
              .where(iid: merge_request_ids.to_a)
              .includes(target_project: :namespace)

            merge_requests.each do |merge_request|
              hash[project][merge_request.iid.to_i] = merge_request
            end
          end

          hash
        end
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
