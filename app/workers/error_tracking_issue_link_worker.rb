# frozen_string_literal: true

# Creates a link in Sentry between a Sentry issue and a GitLab issue.
# If the link already exists, no changes will occur.
# If a link to a different GitLab issue exists, a new link
#   will still be created, but will not be visible in Sentry
#   until the prior link is deleted.
class ErrorTrackingIssueLinkWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ExclusiveLeaseGuard
  include Gitlab::Utils::StrongMemoize

  feature_category :error_tracking
  worker_has_external_dependencies!

  LEASE_TIMEOUT = 15.minutes

  attr_reader :issue

  def perform(issue_id)
    @issue = Issue.find_by_id(issue_id)

    return unless valid?

    try_obtain_lease do
      logger.info("Linking Sentry issue #{sentry_issue_id} to GitLab issue #{issue.id}")

      sentry_client.create_issue_link(integration_id, sentry_issue_id, issue)
    rescue ErrorTracking::SentryClient::Error => e
      logger.info("Failed to link Sentry issue #{sentry_issue_id} to GitLab issue #{issue.id} with error: #{e.message}")
    end
  end

  private

  def valid?
    issue && error_tracking && sentry_issue_id
  end

  def error_tracking
    strong_memoize(:error_tracking) do
      issue.project.error_tracking_setting
    end
  end

  def sentry_issue_id
    strong_memoize(:sentry_issue_id) do
      issue.sentry_issue.sentry_issue_identifier
    end
  end

  def sentry_client
    error_tracking.sentry_client
  end

  def integration_id
    strong_memoize(:integration_id) do
      repo&.integration_id
    end
  end

  def repo
    sentry_client
      .repos(organization_slug)
      .find { |repo| repo.project_id == issue.project_id && repo.status == 'active' }
  rescue ErrorTracking::SentryClient::Error => e
    logger.info("Unable to retrieve Sentry repo for organization #{organization_slug}, id #{sentry_issue_id}, with error: #{e.message}")

    nil
  end

  def organization_slug
    error_tracking.organization_slug
  end

  def project_url
    ::Gitlab::Routing.url_helpers.project_url(issue.project)
  end

  def lease_key
    "link_sentry_issue_#{sentry_issue_id}_gitlab_#{issue.id}"
  end

  def lease_timeout
    LEASE_TIMEOUT
  end
end
