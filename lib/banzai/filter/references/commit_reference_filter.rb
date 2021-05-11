# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces commit references with links.
      #
      # This filter supports cross-project references.
      class CommitReferenceFilter < AbstractReferenceFilter
        self.reference_type = :commit
        self.object_class   = Commit

        def references_in(text, pattern = object_reference_pattern)
          text.gsub(pattern) do |match|
            yield match, $~[:commit], $~[:project], $~[:namespace], $~
          end
        end

        def find_object(project, id)
          return unless project.is_a?(Project) && project.valid_repo?

          _, record = reference_cache.records_per_parent[project].detect { |k, _v| Gitlab::Git.shas_eql?(k, id) }

          record
        end

        def referenced_merge_request_commit_shas
          return [] unless noteable.is_a?(MergeRequest)

          @referenced_merge_request_commit_shas ||= begin
            referenced_shas = reference_cache.references_per_parent.values.reduce(:|).to_a
            noteable.all_commit_shas.select do |sha|
              referenced_shas.any? { |ref| Gitlab::Git.shas_eql?(sha, ref) }
            end
          end
        end

        # The default behaviour is `#to_i` - we just pass the hash through.
        def parse_symbol(sha_hash, _match)
          sha_hash
        end

        def url_for_object(commit, project)
          h = Gitlab::Routing.url_helpers

          if referenced_merge_request_commit_shas.include?(commit.id)
            h.diffs_project_merge_request_url(project,
                                              noteable,
                                              commit_id: commit.id,
                                              only_path: only_path?)
          else
            h.project_commit_url(project,
                                 commit,
                                 only_path: only_path?)
          end
        end

        def object_link_text_extras(object, matches)
          extras = super

          path = matches[:path] if matches.names.include?("path")
          if path == '/builds'
            extras.unshift "builds"
          end

          extras
        end

        def parent_records(parent, ids)
          parent.commits_by(oids: ids.to_a)
        end

        private

        def noteable
          context[:noteable]
        end

        def only_path?
          context[:only_path]
        end
      end
    end
  end
end
