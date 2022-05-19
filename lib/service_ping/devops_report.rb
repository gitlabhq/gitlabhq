# frozen_string_literal: true

module ServicePing
  class DevopsReport
    def initialize(data)
      @data = data
    end

    def execute
      # `conv_index` was previously named `dev_ops_score` in
      # version-gitlab-com, so we check both for backwards compatibility.
      metrics = @data['conv_index'] || @data['dev_ops_score']

      # Do not attempt to save a report for the first Service Ping
      # response for a given GitLab instance, which comes without
      # metrics.
      return if metrics.keys == ['usage_data_id']

      report = DevOpsReport::Metric.create(
        metrics.slice(*DevOpsReport::Metric::METRICS)
      )

      unless report.persisted?
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          ActiveRecord::RecordInvalid.new(report)
        )
      end
    end
  end
end
