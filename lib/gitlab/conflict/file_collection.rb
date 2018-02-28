module Gitlab
  module Conflict
    class FileCollection
      attr_reader :merge_request, :resolver

      def initialize(merge_request)
        our_commit = merge_request.source_branch_head.raw
        their_commit = merge_request.target_branch_head.raw
        target_repo = merge_request.target_project.repository.raw
        @source_repo = merge_request.source_project.repository.raw
        @resolver = Gitlab::Git::Conflict::Resolver.new(target_repo, our_commit.id, their_commit.id)
        @merge_request = merge_request
      end

      def resolve(user, commit_message, files)
        msg = commit_message || default_commit_message
        resolution = Gitlab::Git::Conflict::Resolution.new(user, files, msg)
        args = {
          source_branch: merge_request.source_branch,
          target_branch: merge_request.target_branch
        }
        resolver.resolve_conflicts(@source_repo, resolution, args)
      ensure
        @merge_request.clear_memoized_shas
      end

      def files
        @files ||= resolver.conflicts.map do |conflict_file|
          Gitlab::Conflict::File.new(conflict_file, merge_request: merge_request)
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
        conflict_filenames = files.map do |conflict|
          "#   #{conflict.our_path}"
        end

        <<EOM.chomp
Merge branch '#{merge_request.target_branch}' into '#{merge_request.source_branch}'

# Conflicts:
#{conflict_filenames.join("\n")}
EOM
      end
    end
  end
end
