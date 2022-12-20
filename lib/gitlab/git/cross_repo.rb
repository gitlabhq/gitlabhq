# frozen_string_literal: true

module Gitlab
  module Git
    class CrossRepo
      attr_reader :source_repo, :target_repo

      def initialize(source_repo, target_repo)
        @source_repo = source_repo
        @target_repo = target_repo
      end

      def execute(target_ref, &blk)
        ensuring_ref_in_source(target_ref, &blk)
      end

      private

      def ensuring_ref_in_source(ref, &blk)
        return yield ref if source_repo == target_repo

        # If the commit doesn't exist in the target, there's nothing we can do
        commit_id = target_repo.commit(ref)&.sha
        return unless commit_id

        # The commit pointed to by ref may exist in the source even when they
        # are different repositories. This is particularly true of close forks,
        # but may also be the case if a temporary ref for this comparison has
        # already been created in the past, and the result hasn't been GC'd yet.
        return yield commit_id if source_repo.commit(commit_id)

        # Worst case: the commit is not in the source repo so we need to fetch
        # it. Use a temporary ref and clean up afterwards
        with_commit_in_source_tmp(commit_id, &blk)
      end

      # Fetch the ref into source_repo from target_repo, using a temporary ref
      # name that will be deleted once the method completes. This is a no-op if
      # fetching the source branch fails
      def with_commit_in_source_tmp(commit_id, &blk)
        tmp_ref = "refs/#{::Repository::REF_TMP}/#{SecureRandom.hex}"

        yield commit_id if source_repo.fetch_source_branch!(target_repo, commit_id, tmp_ref)
      ensure
        source_repo.delete_refs(tmp_ref) # best-effort
      end
    end
  end
end
