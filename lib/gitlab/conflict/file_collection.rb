module Gitlab
  module Conflict
    class FileCollection
      ConflictSideMissing = Class.new(StandardError)

      attr_reader :merge_request, :our_commit, :their_commit, :project

      delegate :repository, to: :project

      class << self
        # We can only write when getting the merge index from the source
        # project, because we will write to that project. We don't use this all
        # the time because this fetches a ref into the source project, which
        # isn't needed for reading.
        def for_resolution(merge_request)
          project = merge_request.source_project

          new(merge_request, project).tap do |file_collection|
            project
              .repository
              .with_repo_branch_commit(merge_request.target_project.repository, merge_request.target_branch) do

              yield file_collection
            end
          end
        end

        # We don't need to do `with_repo_branch_commit` here, because the target
        # project always fetches source refs when creating merge request diffs.
        def read_only(merge_request)
          new(merge_request, merge_request.target_project)
        end
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

      def file_for_path(old_path, new_path)
        files.find { |file| file.their_path == old_path && file.our_path == new_path }
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
Merge branch '#{merge_request.target_branch}' into '#{merge_request.source_branch}'

# Conflicts:
#{conflict_filenames.join("\n")}
EOM
      end

      private

      def initialize(merge_request, project)
        @merge_request = merge_request
        @our_commit = merge_request.source_branch_head.raw.rugged_commit
        @their_commit = merge_request.target_branch_head.raw.rugged_commit
        @project = project
      end
    end
  end
end
