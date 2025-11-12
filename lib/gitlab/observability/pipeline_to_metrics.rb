# frozen_string_literal: true

module Gitlab
  module Observability
    class PipelineToMetrics
      include Gitlab::Utils::StrongMemoize

      HISTOGRAM_BUCKETS = [1, 5, 10, 30, 60, 300, 600, 1800, 3600].freeze

      def initialize(integration, pipeline_data)
        @integration = integration
        @pipeline_data = pipeline_data
        @pipeline = pipeline_data[:object_attributes]
        @builds = pipeline_data[:builds] || []
      end

      def convert
        return empty_metrics_payload if @pipeline.blank?

        {
          resourceMetrics: [
            {
              resource: build_resource,
              scopeMetrics: [
                {
                  scope: build_scope,
                  metrics: build_metrics
                }
              ]
            }
          ]
        }
      end

      private

      attr_reader :integration, :pipeline_data, :pipeline, :builds

      def empty_metrics_payload
        { resourceMetrics: [] }
      end

      def build_resource
        {
          attributes: [
            { key: 'service.name', value: { stringValue: service_name } },
            { key: 'service.version', value: { stringValue: '1.0.0' } },
            { key: 'deployment.environment', value: { stringValue: environment } },
            { key: 'gitlab.project.id', value: { intValue: pipeline_data.dig(:project, :id) } },
            { key: 'gitlab.project.name', value: { stringValue: pipeline_data.dig(:project, :name) } },
            { key: 'gitlab.pipeline.id', value: { intValue: pipeline[:id] } },
            { key: 'gitlab.pipeline.ref', value: { stringValue: pipeline[:ref] } }
          ]
        }
      end

      def build_scope
        {
          name: 'gitlab-ci-metrics',
          version: '1.0.0'
        }
      end

      def build_metrics
        metrics = []

        metrics << build_pipeline_duration_metric if pipeline[:duration] && pipeline[:duration] > 0

        metrics << build_pipeline_status_counter

        metrics << build_job_count_gauge

        metrics << build_job_duration_histogram if builds.any?

        metrics << build_queue_duration_metric if pipeline[:queued_duration] && pipeline[:queued_duration] > 0

        metrics
      end

      def build_pipeline_duration_metric
        {
          name: 'pipeline.duration_seconds',
          description: 'Duration of the pipeline execution in seconds',
          unit: 's',
          gauge: {
            dataPoints: [
              {
                timeUnixNano: current_time_nanoseconds,
                asDouble: pipeline[:duration] / 1000.0,
                attributes: [
                  { key: 'pipeline.status', value: { stringValue: pipeline[:status] } },
                  { key: 'pipeline.ref', value: { stringValue: pipeline[:ref] } }
                ]
              }
            ]
          }
        }
      end

      def build_pipeline_status_counter
        {
          name: 'pipeline.status_total',
          description: 'Total number of pipeline status changes',
          unit: '1',
          sum: {
            isMonotonic: true,
            aggregationTemporality: 'AGGREGATION_TEMPORALITY_DELTA',
            dataPoints: [
              {
                timeUnixNano: current_time_nanoseconds,
                asInt: 1,
                attributes: [
                  { key: 'pipeline.status', value: { stringValue: pipeline[:status] } },
                  { key: 'pipeline.ref', value: { stringValue: pipeline[:ref] } }
                ]
              }
            ]
          }
        }
      end

      def build_job_count_gauge
        {
          name: 'pipeline.jobs_total',
          description: 'Total number of jobs in the pipeline',
          unit: '1',
          gauge: {
            dataPoints: [
              {
                timeUnixNano: current_time_nanoseconds,
                asInt: builds.count,
                attributes: [
                  { key: 'pipeline.status', value: { stringValue: pipeline[:status] } },
                  { key: 'pipeline.ref', value: { stringValue: pipeline[:ref] } }
                ]
              }
            ]
          }
        }
      end

      def build_job_duration_histogram
        jobs_by_stage = builds.group_by { |build| build[:stage] }

        data_points = jobs_by_stage.filter_map do |stage, stage_jobs|
          durations = stage_jobs.filter_map { |job| job[:duration] }
          next if durations.empty?

          {
            timeUnixNano: current_time_nanoseconds,
            count: durations.length,
            sum: durations.sum,
            bucketCounts: build_histogram_buckets(durations),
            explicitBounds: HISTOGRAM_BUCKETS,
            attributes: [
              { key: 'job.stage', value: { stringValue: stage } },
              { key: 'pipeline.status', value: { stringValue: pipeline[:status] } }
            ]
          }
        end

        return if data_points.empty?

        {
          name: 'job.duration_seconds',
          description: 'Duration of job execution by stage in seconds',
          unit: 's',
          histogram: {
            dataPoints: data_points,
            aggregationTemporality: 'AGGREGATION_TEMPORALITY_DELTA'
          }
        }
      end

      def build_queue_duration_metric
        {
          name: 'pipeline.queue_duration_seconds',
          description: 'Time spent in queue before pipeline execution',
          unit: 's',
          gauge: {
            dataPoints: [
              {
                timeUnixNano: current_time_nanoseconds,
                asDouble: pipeline[:queued_duration] / 1000.0,
                attributes: [
                  { key: 'pipeline.status', value: { stringValue: pipeline[:status] } },
                  { key: 'pipeline.ref', value: { stringValue: pipeline[:ref] } }
                ]
              }
            ]
          }
        }
      end

      def build_histogram_buckets(durations)
        bounds = HISTOGRAM_BUCKETS
        buckets = Array.new(bounds.length + 1, 0)

        durations.each do |duration|
          # Convert milliseconds to seconds for comparison and bucket indexing
          bucket_index = bounds.find_index { |bound| duration <= bound * 1000 }
          bucket_index = bounds.length if bucket_index.nil?
          buckets[bucket_index] += 1
        end

        buckets
      end

      def service_name
        integration.service_name.presence || pipeline_data.dig(:project, :name) || 'gitlab-ci'
      end

      def environment
        integration.environment.presence || 'production'
      end

      def current_time_nanoseconds
        Time.current.to_i * 1_000_000_000
      end
    end
  end
end
