# frozen_string_literal: true

module Projects
  class UpdateRemoteMirrorService < BaseService
    include Gitlab::Utils::StrongMemoize

    MAX_TRIES = 3

    def execute(remote_mirror, tries)
      return success unless remote_mirror.enabled?

      if Gitlab::UrlBlocker.blocked_url?(normalized_url(remote_mirror.url))
        return error("The remote mirror URL is invalid.")
      end

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

    def normalized_url(url)
      strong_memoize(:normalized_url) do
        CGI.unescape(Gitlab::UrlSanitizer.sanitize(url))
      end
    end

    def update_mirror(remote_mirror)
      remote_mirror.update_start!
      remote_mirror.ensure_remote!

      # LFS objects must be sent first, or the push has dangling pointers
      send_lfs_objects!(remote_mirror)

      response = remote_mirror.update_repository

      if response.divergent_refs.any?
        message = "Some refs have diverged and have not been updated on the remote:"
        message += "\n\n#{response.divergent_refs.join("\n")}"

        remote_mirror.mark_as_failed!(message)
      else
        remote_mirror.update_finish!
      end
    end

    def send_lfs_objects!(remote_mirror)
      return unless project.lfs_enabled?

      # TODO: Support LFS sync over SSH
      # https://gitlab.com/gitlab-org/gitlab/-/issues/249587
      return unless remote_mirror.url =~ /\Ahttps?:\/\//i
      return unless remote_mirror.password_auth?

      Lfs::PushService.new(
        project,
        current_user,
        url: remote_mirror.bare_url,
        credentials: remote_mirror.credentials
      ).execute
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
