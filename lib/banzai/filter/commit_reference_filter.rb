module Banzai
  module Filter
    # HTML filter that replaces commit references with links.
    #
    # This filter supports cross-project references.
    class CommitReferenceFilter < AbstractReferenceFilter
      self.reference_type = :commit

      def self.object_class
        Commit
      end

      def self.references_in(text, pattern = Commit.reference_pattern)
        text.gsub(pattern) do |match|
          yield match, $~[:commit], $~[:project], $~[:namespace], $~
        end
      end

      def find_object(project, id)
        return unless project.is_a?(Project)

        if project && project.valid_repo?
          # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/43894
          Gitlab::GitalyClient.allow_n_plus_1_calls { project.commit(id) }
        end
      end

      def referenced_merge_request_commit_shas
        return [] unless noteable.is_a?(MergeRequest)

        @referenced_merge_request_commit_shas ||= begin
          referenced_shas = references_per_parent.values.reduce(:|).to_a
          noteable.all_commit_shas.select do |sha|
            referenced_shas.any? { |ref| Gitlab::Git.shas_eql?(sha, ref) }
          end
        end
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
