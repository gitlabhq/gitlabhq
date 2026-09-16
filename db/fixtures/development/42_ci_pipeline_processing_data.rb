# frozen_string_literal: true

# Usage:
#
# For every existing pipeline that doesn't already have one, creates a
# Ci::PipelineProcessingData, protecting a few of them from auto-cancellation.
# Safe to re-run: pipelines that already have one are skipped.
#
# FILTER=42_ci_pipeline_processing_data bundle exec rake db:seed_fu
#
# Seed more of them, useful when generating query plans:
#
# FILTER=42_ci_pipeline_processing_data COUNT=1000 bundle exec rake db:seed_fu

Gitlab::Seeder.quiet do
  count = [ENV.fetch('COUNT', 10).to_i, 1].max

  # Ci::PipelineProcessingData is 1:1 per pipeline, keyed by [pipeline_id, partition_id],
  # so only seed pipelines that don't already have one, to stay idempotent across reruns.
  pipelines_without_processing_data =
    Ci::Pipeline.left_joins(:pipeline_processing_data)
      .where(p_ci_pipeline_processing_data: { pipeline_id: nil })
      .limit(count)

  if pipelines_without_processing_data.empty?
    puts "\nNo Ci::Pipeline records without processing data, run the 14_pipelines seed first.\n"
  else
    pipelines_without_processing_data.each_with_index do |pipeline, index|
      print '.' if (index % 100).zero?

      Ci::PipelineProcessingData.create!(
        pipeline: pipeline,
        project_id: pipeline.project_id,
        # A non-interruptible job has started for some of them, which takes the
        # pipeline out of reach of auto-cancellation.
        interruptible_protected: (index % 3).zero?
      )
    end
  end
end
