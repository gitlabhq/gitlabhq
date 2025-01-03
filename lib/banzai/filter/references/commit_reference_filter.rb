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
          Gitlab::Utils::Gsub.gsub_with_limit(text, pattern, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match_data|
            yield match_data[0], match_data[:commit], match_data[:project], match_data[:namespace],
              match_data
          end
        end

        def find_object(project, id)
          return unless project.is_a?(Project) && project.valid_repo?

          # Optimization: try exact commit hash match first
          record = reference_cache.records_per_parent[project].fetch(id, nil)

          unless record
            _, record = reference_cache.records_per_parent[project].detect { |k, _v| Gitlab::Git.shas_eql?(k, id) }
          end

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
            h.diffs_project_merge_request_url(
              project,
              noteable,
              commit_id: commit.id,
              only_path: only_path?
            )
          else
            h.project_commit_url(project, commit, only_path: only_path?)
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
          return [] unless parent.respond_to?(:commits_by)

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
