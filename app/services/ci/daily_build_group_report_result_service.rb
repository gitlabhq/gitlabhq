# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResultService
    def execute(pipeline)
      if DailyBuildGroupReportResult.upsert_reports(coverage_reports(pipeline))
        Projects::CiFeatureUsage.insert_usage(
          project_id: pipeline.project_id,
          feature: :code_coverage,
          default_branch: pipeline.default_branch?
        )
      end
    end

    private

    def coverage_reports(pipeline)
      base_attrs = {
        project_id: pipeline.project_id,
        ref_path: pipeline.source_ref_path,
        date: pipeline.created_at.to_date,
        last_pipeline_id: pipeline.id,
        default_branch: pipeline.default_branch?,
        group_id: pipeline.project&.group&.id,
        partition_id: pipeline.partition_id
      }

      aggregate(pipeline.builds.with_coverage).map do |group_name, group|
        base_attrs.merge(
          group_name: group_name,
          data: {
            'coverage' => average_coverage(group)
          }
        )
      end
    end

    def aggregate(builds)
      builds.group_by(&:group_name)
    end

    def average_coverage(group)
      total_coverage = group.reduce(0.0) { |sum, build| sum + build.coverage }
      (total_coverage / group.size).round(2)
    end
  end
end
