# frozen_string_literal: true

module Projects
  # The CleanupService removes data from the project repository following a
  # BFG rewrite: https://rtyley.github.io/bfg-repo-cleaner/
  #
  # Before executing this service, all refs rewritten by BFG should have been
  # pushed to the repository
  class CleanupService < BaseService
    NoUploadError = StandardError.new("Couldn't find uploaded object map")

    include Gitlab::Utils::StrongMemoize

    class << self
      def enqueue(project, current_user, bfg_object_map)
        Projects::UpdateService.new(project, current_user, bfg_object_map: bfg_object_map).execute.tap do |result|
          next unless result[:status] == :success

          project.set_repository_read_only!
          RepositoryCleanupWorker.perform_async(project.id, current_user.id)
        end
      rescue Project::RepositoryReadOnlyError => err
        { status: :error, message: (_('Failed to make repository read-only. %{reason}') % { reason: err.message }) }
      end

      def cleanup_after(project)
        project.bfg_object_map.remove!
        project.set_repository_writable!
      end
    end

    # Attempt to clean up the project following the push. Warning: this is
    # destructive!
    #
    # path is the path of an upload of a BFG object map file. It contains a line
    # per rewritten object, with the old and new SHAs space-separated. It can be
    # used to update or remove content that references the objects that BFG has
    # altered
    def execute
      apply_bfg_object_map!

      # Remove older objects that are no longer referenced
      Projects::GitGarbageCollectWorker.new.perform(project.id, :prune, "project_cleanup:gc:#{project.id}")

      # The cache may now be inaccurate, and holding onto it could prevent
      # bugs assuming the presence of some object from manifesting for some
      # time. Better to feel the pain immediately.
      project.repository.expire_all_method_caches

      self.class.cleanup_after(project)
    end

    private

    def apply_bfg_object_map!
      raise NoUploadError unless project.bfg_object_map.exists?

      project.bfg_object_map.open do |io|
        repository_cleaner.apply_bfg_object_map_stream(io) do |response|
          cleanup_diffs(response)
        end
      end
    end

    def cleanup_diffs(response)
      old_commit_shas = extract_old_commit_shas(response.entries)

      ApplicationRecord.transaction do
        cleanup_merge_request_diffs(old_commit_shas)
        cleanup_note_diff_files(old_commit_shas)
      end
    end

    def extract_old_commit_shas(batch)
      batch.lazy.select { |entry| entry.type == :COMMIT }.map(&:old_oid).force
    end

    def cleanup_merge_request_diffs(old_commit_shas)
      merge_request_diffs = MergeRequestDiff
        .by_project_id(project.id)
        .by_commit_sha(old_commit_shas)

      # It's important to run the ActiveRecord callbacks here
      merge_request_diffs.destroy_all # rubocop:disable Cop/DestroyAll

      # TODO: ensure the highlight cache is removed immediately. It's too hard
      # to calculate the Redis keys at present.
      #
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/61115
    end

    def cleanup_note_diff_files(old_commit_shas)
      # Pluck the IDs instead of running the query twice to ensure we clear the
      # cache for exactly the note diffs we remove
      ids = NoteDiffFile
        .referencing_sha(old_commit_shas, project_id: project.id)
        .pluck_primary_key

      NoteDiffFile.id_in(ids).delete_all

      # A highlighted version of the diff is stored in redis. Remove it now.
      Gitlab::DiscussionsDiff::HighlightCache.clear_multiple(ids)
    end

    def repository_cleaner
      @repository_cleaner ||= Gitlab::Git::RepositoryCleaner.new(repository.raw)
    end
  end
end

Projects::CleanupService.prepend_mod_with('Projects::CleanupService')
