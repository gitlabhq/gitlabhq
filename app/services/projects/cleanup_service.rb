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

    # Attempt to clean up the project following the push. Warning: this is
    # destructive!
    #
    # path is the path of an upload of a BFG object map file. It contains a line
    # per rewritten object, with the old and new SHAs space-separated. It can be
    # used to update or remove content that references the objects that BFG has
    # altered
    #
    # Currently, only the project repository is modified by this service, but we
    # may wish to modify other data sources in the future.
    def execute
      apply_bfg_object_map!

      # Remove older objects that are no longer referenced
      GitGarbageCollectWorker.new.perform(project.id, :gc)

      # The cache may now be inaccurate, and holding onto it could prevent
      # bugs assuming the presence of some object from manifesting for some
      # time. Better to feel the pain immediately.
      project.repository.expire_all_method_caches

      project.bfg_object_map.remove!
    end

    private

    def apply_bfg_object_map!
      raise NoUploadError unless project.bfg_object_map.exists?

      project.bfg_object_map.open do |io|
        repository_cleaner.apply_bfg_object_map(io)
      end
    end

    def repository_cleaner
      @repository_cleaner ||= Gitlab::Git::RepositoryCleaner.new(repository.raw)
    end
  end
end
