namespace :gitlab do
  desc 'GitLab | Tracks a deployment in GitLab Performance Monitoring'
  task track_deployment: :environment do
    metric = Gitlab::Metrics::Metric.
      new('deployments', version: Gitlab::VERSION)

    Gitlab::Metrics.submit_metrics([metric.to_hash])
  end
end
