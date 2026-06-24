# frozen_string_literal: true

module Projects
  class UpdateRemoteMirrorService < BaseService
    include Gitlab::Utils::StrongMemoize

    MAX_TRIES = 3

    def execute(remote_mirror, tries)
      return success unless remote_mirror.enabled?

      @remote_mirror = remote_mirror

      # Blocked URLs are a hard failure, no need to attempt to retry
      #
      begin
        validate_remote_url!
      rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
        message = format(_('The remote mirror URL is invalid: %{message}'), message: e.message)
        hard_retry_or_fail(remote_mirror, message, tries)
        return error(remote_mirror.last_error)
      end

      update_mirror(remote_mirror)

      success
    rescue Gitlab::Git::CommandError => e
      # This happens if one of the gitaly calls above fail, for example when
      # branches have diverged, or the pre-receive hook fails.
      hard_retry_or_fail(remote_mirror, e.message, tries)

      error(e.message)
    rescue StandardError => e
      remote_mirror.hard_fail!(e.message)
      raise e
    end

    private

    def normalized_url(url)
      strong_memoize_with(:normalized_url, url) do
        CGI.unescape(Gitlab::UrlSanitizer.sanitize(url))
      end
    end

    # Validates the remote mirror URL and memoizes the result.
    # Returns [validated_url, resolved_host] or nil if URL is blank.
    # Raises BlockedUrlError if URL is blocked.
    #
    strong_memoize_attr def validated_url_result
      return unless @remote_mirror&.url

      Gitlab::HTTP_V2::UrlBlocker.validate!(
        normalized_url(@remote_mirror.url),
        schemes: Project::VALID_MIRROR_PROTOCOLS,
        allow_localhost: allow_local_requests?,
        allow_local_network: allow_local_requests?,
        dns_rebind_protection: dns_rebind_protection?,
        deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
        outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist) # rubocop:disable Naming/InclusiveLanguage -- existing setting
    end

    def validate_remote_url!
      validated_url_result # raises BlockedUrlError if blocked
    end

    # Returns the resolved IP address for HTTP/HTTPS/Git URLs to prevent DNS rebinding attacks.
    # For SSH URLs or when resolved_host is nil, returns an empty string.
    #
    # Note: SSH URLs don't need DNS rebinding protection because SSH connections
    # verify the host key, which is tied to the server's identity.
    #
    def resolved_address
      result = validated_url_result
      return '' unless result

      validated_url, resolved_host = result
      return '' if resolved_host.nil? || !validated_url.scheme.in?(%w[http https git])

      validated_url.hostname.to_s
    end

    def allow_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def dns_rebind_protection?
      return false if Gitlab.http_proxy_env?

      Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
    end

    def update_mirror(remote_mirror)
      remote_mirror.update_start!

      # LFS objects must be sent first, or the push has dangling pointers
      lfs_status = send_lfs_objects!(remote_mirror)

      response = remote_mirror.update_repository(resolved_address: resolved_address)
      failed, failure_message = failure_status(lfs_status, response, remote_mirror)

      # When the issue https://gitlab.com/gitlab-org/gitlab/-/issues/349262 is closed,
      # we can move this block within failure_status.
      if failed
        remote_mirror.mark_as_failed!(failure_message)
      else
        remote_mirror.update_finish!
      end
    end

    def failure_status(lfs_status, response, remote_mirror)
      message = ''
      failed = false
      lfs_sync_failed = false

      if lfs_status&.dig(:status) == :error
        lfs_sync_failed = true
        message += "Error synchronizing LFS files:"
        message += "\n\n#{lfs_status[:message]}\n\n"
      end

      if response.divergent_refs.any?
        message += "Some refs have diverged and have not been updated on the remote:"
        message += "\n\n#{response.divergent_refs.join("\n")}"
        failed = true
      end

      if message.present?
        Gitlab::AppJsonLogger.info(
          message: "Error synching remote mirror",
          project_id: project.id,
          project_path: project.full_path,
          remote_mirror_id: remote_mirror.id,
          lfs_sync_failed: lfs_sync_failed,
          divergent_ref_list: response.divergent_refs
        )
      end

      [failed, message]
    end

    def send_lfs_objects!(remote_mirror)
      return unless project.lfs_enabled?

      # TODO: Support LFS sync over SSH
      # https://gitlab.com/gitlab-org/gitlab/-/issues/249587
      return unless %r{\Ahttps?://}i.match?(remote_mirror.url)
      return unless remote_mirror.password_auth?

      Lfs::PushService.new(
        project,
        current_user,
        url: remote_mirror.bare_url,
        credentials: remote_mirror.credentials
      ).execute
    end

    def hard_retry_or_fail(mirror, message, tries)
      if tries < MAX_TRIES
        mirror.hard_retry!(message)
      else
        # It's not likely we'll be able to recover from this ourselves, so we'll
        # notify the users of the problem, and don't trigger any sidekiq retries
        # Instead, we'll wait for the next change to try the push again, or until
        # a user manually retries.
        mirror.hard_fail!(message)
      end
    end
  end
end
