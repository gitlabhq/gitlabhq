module Gitlab
  module Conflict
    class FileCollection
      attr_reader :merge_request, :our_commit, :their_commit

      def initialize(merge_request)
        @merge_request = merge_request
        @our_commit = merge_request.diff_head_commit.raw.raw_commit
        @their_commit = merge_request.target_branch_head.raw.raw_commit
      end

      def repository
        merge_request.project.repository
      end

      def merge_index
        @merge_index ||= repository.rugged.merge_commits(our_commit, their_commit)
      end

      def resolve_conflicts!(resolutions, commit_message, user:)
        rugged = repository.rugged
        committer = repository.user_to_committer(user)
        commit_message ||= default_commit_message

        files.each do |file|
          file.resolve!(resolutions, index: merge_index, rugged: rugged)
        end

        new_tree = merge_index.write_tree(rugged)

        Rugged::Commit.create(rugged,
                              author: committer,
                              committer: committer,
                              tree: new_tree,
                              message: commit_message,
                              parents: [our_commit, their_commit],
                              update_ref: Gitlab::Git::BRANCH_REF_PREFIX + merge_request.source_branch)
      end

      def files
        @files ||= merge_index.conflicts.map do |conflict|
          their_path = conflict[:theirs][:path]
          our_path = conflict[:ours][:path]

          # TODO remove this
          raise 'path mismatch!' unless their_path == our_path

          Gitlab::Conflict::File.new(merge_index.merge_file(our_path),
                                     conflict,
                                     diff_refs: merge_request.diff_refs,
                                     repository: repository)
        end
      end

      def as_json(opts = nil)
        {
          target_branch: merge_request.target_branch,
          source_branch: merge_request.source_branch,
          commit_sha: merge_request.diff_head_sha,
          commit_message: default_commit_message,
          files: files
        }
      end

      def default_commit_message
        conflict_filenames = merge_index.conflicts.map do |conflict|
          "#   #{conflict[:ours][:path]}"
        end

        <<EOM.chomp
Merge branch '#{merge_request.source_branch}' into '#{merge_request.target_branch}'

# Conflicts:
#{conflict_filenames.join("\n")}
EOM
      end
    end
  end
end
