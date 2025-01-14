# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces merge request references with links. References
      # to merge requests that do not exist are ignored.
      #
      # This filter supports cross-project references.
      class MergeRequestReferenceFilter < IssuableReferenceFilter
        self.reference_type = :merge_request
        self.object_class   = MergeRequest

        def url_for_object(mr, project)
          h = Gitlab::Routing.url_helpers
          h.project_merge_request_url(project, mr, only_path: context[:only_path])
        end

        def object_link_text_extras(object, matches)
          extras = super

          if commit_ref = object_link_commit_ref(object, matches)
            klass = reference_class(:commit, tooltip: false)
            commit_ref_tag = %(<span class="#{klass}">#{commit_ref}</span>)

            return extras.unshift(commit_ref_tag)
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
          return MergeRequest.none unless parent.is_a?(Project)

          parent.merge_requests
            .where(iid: ids.to_a)
            .includes(target_project: :namespace)
        end

        def reference_class(object_sym, tooltip: false)
          super
        end

        def data_attributes_for(text, parent, object, **data)
          super.merge(project_path: parent.full_path, iid: object.iid)
        end

        private

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
end
