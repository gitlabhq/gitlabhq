namespace :gitlab do
  desc "GitLab | Generate Sample Prometheus Data"
  task :generate_sample_prometheus_data, [:environment_id] => :gitlab_environment do |_, args|
    environment = Environment.find(args[:environment_id])
    metrics = PrometheusMetric.where(project_id: [environment.project.id, nil])
    query_variables = Gitlab::Prometheus::QueryVariables.call(environment)

    sample_metrics_directory_name = Metrics::SampleMetricsService::DIRECTORY
    FileUtils.mkdir_p(sample_metrics_directory_name)

    metrics.each do |metric|
      query = metric.query % query_variables
      result = environment.prometheus_adapter.prometheus_client.query_range(query, start: 7.days.ago)

      next unless metric.identifier

      File.write("#{sample_metrics_directory_name}/#{metric.identifier}.yml", result.to_yaml)
    end
  end
end
