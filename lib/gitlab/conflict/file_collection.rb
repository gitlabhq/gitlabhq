# frozen_string_literal: true

module Gitlab
  module Conflict
    class FileCollection
      include Gitlab::RepositoryCacheAdapter

      attr_reader :merge_request, :resolver

      def initialize(merge_request, allow_tree_conflicts: false, skip_content: false)
        @our_commit = merge_request.source_branch_head.raw
        @their_commit = merge_request.target_branch_head.raw
        @target_repo = merge_request.target_project.repository
        @source_repo = merge_request.source_project.repository.raw
        @our_commit_id = @our_commit.id
        @their_commit_id = @their_commit.id
        @resolver = Gitlab::Git::Conflict::Resolver.new(@target_repo.raw, @our_commit_id, @their_commit_id, allow_tree_conflicts: allow_tree_conflicts, skip_content: skip_content)
        @merge_request = merge_request
      end

      def resolve(user, commit_message, files)
        msg = commit_message || default_commit_message
        resolution = Gitlab::Git::Conflict::Resolution.new(user, files, msg)

        resolver.resolve_conflicts(
          @source_repo,
          resolution,
          source_branch: merge_request.source_branch,
          target_branch: merge_request.target_branch
        )
      ensure
        @merge_request.clear_memoized_shas
      end

      def files
        @files ||= resolver.conflicts.map do |conflict_file|
          Gitlab::Conflict::File.new(conflict_file, merge_request: merge_request)
        end
      end

      def can_be_resolved_in_ui?
        # Try to parse each conflict. If the MR's mergeable status hasn't been
        # updated, ensure that we don't say there are conflicts to resolve
        # when there are no conflict files.
        files.each(&:lines)
        files.any?
      rescue Gitlab::Git::CommandError,
             Gitlab::Git::Conflict::Parser::UnresolvableError,
             Gitlab::Git::Conflict::Resolver::ConflictSideMissing,
             Gitlab::Git::Conflict::File::UnsupportedEncoding
        false
      end
      cache_method :can_be_resolved_in_ui?

      def file_for_path(old_path, new_path)
        files.find { |file| file.their_path == old_path && file.our_path == new_path }
      end

      def as_json(opts = nil)
        {
          target_branch: merge_request.target_branch,
          source_commit: {
            sha: @our_commit.id,
            message: @our_commit.message
          },
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

      private

      def cache
        @cache ||= begin
          # Use the commit ids as a namespace so if the MR branches get
          # updated we instantiate the cache under a different namespace. That
          # way don't have to worry about explicitly invalidating the cache
          namespace = "#{@our_commit_id}:#{@their_commit_id}"

          Gitlab::RepositoryCache.new(@target_repo, extra_namespace: namespace)
        end
      end
    end
  end
end
