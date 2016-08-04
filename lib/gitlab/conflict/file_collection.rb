module Gitlab
  module Conflict
    class FileCollection
      class ConflictSideMissing < StandardError
      end

      attr_reader :merge_request, :our_commit, :their_commit

      def initialize(merge_request)
        @merge_request = merge_request
        @our_commit = merge_request.source_branch_head.raw.raw_commit
        @their_commit = merge_request.target_branch_head.raw.raw_commit
      end

      def repository
        merge_request.project.repository
      end

      def merge_index
        @merge_index ||= repository.rugged.merge_commits(our_commit, their_commit)
      end

      def files
        @files ||= merge_index.conflicts.map do |conflict|
          raise ConflictSideMissing unless conflict[:theirs] && conflict[:ours]

          Gitlab::Conflict::File.new(merge_index.merge_file(conflict[:ours][:path]),
                                     conflict,
                                     merge_request: merge_request)
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
