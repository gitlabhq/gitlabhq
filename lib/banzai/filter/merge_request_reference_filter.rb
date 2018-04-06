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

      def object_link_title(object, matches)
        object_link_commit_title(object, matches) || super
      end

      def object_link_text_extras(object, matches)
        extras = super

        if commit_ref = object_link_commit_ref(object, matches)
          return extras.unshift(commit_ref)
        end

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

      private

      def object_link_commit_title(object, matches)
        object_link_commit(object, matches)&.title
      end

      def object_link_commit_ref(object, matches)
        object_link_commit(object, matches)&.short_id
      end

      def object_link_commit(object, matches)
        return unless matches.names.include?('query') && query = matches[:query]

        # Removes leading "?". CGI.parse expects "arg1&arg2&arg3"
        params = CGI.parse(query.sub(/^\?/, ''))

        return unless commit_sha = params['commit_id']&.first

        if commit = find_commit_by_sha(object, commit_sha)
          Commit.from_hash(commit.to_hash, object.project)
        end
      end

      def find_commit_by_sha(object, commit_sha)
        @all_commits ||= {}
        @all_commits[object.id] ||= object.all_commits

        @all_commits[object.id].find { |commit| commit.sha == commit_sha }
      end
    end
  end
end
