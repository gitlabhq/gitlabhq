# frozen_string_literal: true

module Projects
  class UpdateRemoteMirrorService < BaseService
    MAX_TRIES = 3

    def execute(remote_mirror, tries)
      return success unless remote_mirror.enabled?

      update_mirror(remote_mirror)

      success
    rescue Gitlab::Git::CommandError => e
      # This happens if one of the gitaly calls above fail, for example when
      # branches have diverged, or the pre-receive hook fails.
      retry_or_fail(remote_mirror, e.message, tries)

      error(e.message)
    rescue => e
      remote_mirror.mark_as_failed!(e.message)
      raise e
    end

    private

    def update_mirror(remote_mirror)
      remote_mirror.update_start!

      remote_mirror.ensure_remote!
      repository.fetch_remote(remote_mirror.remote_name, ssh_auth: remote_mirror, no_tags: true)

      opts = {}
      if remote_mirror.only_protected_branches?
        opts[:only_branches_matching] = project.protected_branches.select(:name).map(&:name)
      end

      remote_mirror.update_repository(opts)

      remote_mirror.update_finish!
    end

    def retry_or_fail(mirror, message, tries)
      if tries < MAX_TRIES
        mirror.mark_for_retry!(message)
      else
        # It's not likely we'll be able to recover from this ourselves, so we'll
        # notify the users of the problem, and don't trigger any sidekiq retries
        # Instead, we'll wait for the next change to try the push again, or until
        # a user manually retries.
        mirror.mark_as_failed!(message)
      end
    end
  end
end
