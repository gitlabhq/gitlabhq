namespace :gitlab do
  desc "GitLab | Generate Sample Prometheus Data"
  task :generate_sample_prometheus_data, [:environment_id] => :gitlab_environment do |_, args|
    environment = Environment.find(args[:environment_id])
    metrics = PrometheusMetric.where(project_id: [environment.project.id, nil])
    query_variables = Gitlab::Prometheus::QueryVariables.call(environment)

    sample_metrics_directory_name = Metrics::SampleMetricsService::DIRECTORY
    FileUtils.mkdir_p(sample_metrics_directory_name)

    sample_metrics_intervals = [30.minutes, 180.minutes, 8.hours, 24.hours, 72.hours, 7.days]

    metrics.each do |metric|
      query = metric.query % query_variables

      next unless metric.identifier

      result = sample_metrics_intervals.each_with_object({}) do |interval, memo|
        memo[interval.to_i / 60] = environment.prometheus_adapter.prometheus_client.query_range(query, start: interval.ago)
      end

      File.write("#{sample_metrics_directory_name}/#{metric.identifier}.yml", result.to_yaml)
    end
  end
end
