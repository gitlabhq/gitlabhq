# frozen_string_literal: true

class TrendingProjectsWorker
  include ApplicationWorker

  data_consistency :always

  idempotent!

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :source_code_management

  # No-op: the Trending projects feature was removed in GitLab 19.0. The
  # worker class is retained for one release to allow any already-queued
  # jobs to drain harmlessly before the class is deleted.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/555342
  def perform; end
end
