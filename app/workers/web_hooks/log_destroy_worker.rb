# frozen_string_literal: true

module WebHooks
  # This worker was previously scheduled when a WebHook was destroyed, but the
  # large number of writes caused excessive WAL pressure on the DB. This worker
  # is no longer scheduled, and can be removed in a future release.
  # Original issue: https://gitlab.com/gitlab-org/gitlab/-/issues/555121
  # Worker removal issue: https://gitlab.com/gitlab-org/gitlab/-/issues/555405
  # Guidelines: https://docs.gitlab.com/development/sidekiq/compatibility_across_updates/#removing-worker-classes
  class LogDestroyWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :webhooks
    urgency :low

    idempotent!

    def perform(_params = {}); end
  end
end
