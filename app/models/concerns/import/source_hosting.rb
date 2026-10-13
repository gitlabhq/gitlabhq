# frozen_string_literal: true

module Import
  # Determines whether a GitHub or Gitea import points at the SaaS host
  # (`cloud`) or a self-managed instance (`self_hosted`). Used to instrument
  # SaaS vs. self-hosted attribution in import lifecycle internal events.
  module SourceHosting
    extend ActiveSupport::Concern

    CLOUD = 'cloud'
    SELF_HOSTED = 'self_hosted'

    GITHUB_CLOUD_DOMAIN = 'github.com'
    GITEA_CLOUD_DOMAIN = 'gitea.com'

    def gitea_self_hosted_import?
      return false unless gitea_import?

      host = safe_import_host
      return false unless host

      !cloud_host?(host, GITEA_CLOUD_DOMAIN)
    end

    # Returns CLOUD or SELF_HOSTED for github/gitea imports where the source host
    # can be determined, nil otherwise.
    def source_hosting
      return unless github_import? || gitea_import?

      host = safe_import_host
      return unless host

      return SELF_HOSTED if gitea_self_hosted_import?
      return SELF_HOSTED if github_import? && !cloud_host?(host, GITHUB_CLOUD_DOMAIN)

      CLOUD
    end

    private

    def safe_import_host
      URI.parse(safe_import_url.to_s).host
    rescue URI::InvalidURIError
      nil
    end

    def cloud_host?(host, domain)
      host == domain || host.end_with?(".#{domain}")
    end
  end
end
