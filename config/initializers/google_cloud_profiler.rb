# frozen_string_literal: true

return unless Gitlab::Utils.to_boolean(ENV['GITLAB_GOOGLE_CLOUD_PROFILER_ENABLED'])
return unless ENV['GITLAB_GOOGLE_CLOUD_PROFILER_PROJECT_ID']

# For the initial iteration, we enable it only for `web`.
# This is because we have global service accounts configured this way, details:
# https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/17492#note_1303914983
return unless Gitlab::Runtime.puma?

Gitlab::Cluster::LifecycleEvents.on_worker_start do
  require 'cloud_profiler_agent'

  agent = CloudProfilerAgent::Agent.new(
    service: 'gitlab-web',
    project_id: ENV['GITLAB_GOOGLE_CLOUD_PROFILER_PROJECT_ID'],
    logger: ::Gitlab::AppJsonLogger.build,
    log_labels: {
      message: 'Google Cloud Profiler Ruby',
      pid: $$,
      worker_id: ::Prometheus::PidProvider.worker_id
    }
  )
  agent.start
end
