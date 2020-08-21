# frozen_string_literal: true
module Ci
  module Pipelines
    class CreateArtifactService
      def execute(pipeline)
        return unless ::Gitlab::Ci::Features.coverage_report_view?(pipeline.project)
        return unless pipeline.has_coverage_reports?
        return if pipeline.pipeline_artifacts.has_code_coverage?

        file = build_carrierwave_file(pipeline)

        pipeline.pipeline_artifacts.create!(
          project_id: pipeline.project_id,
          file_type: :code_coverage,
          file_format: :raw,
          size: file["tempfile"].size,
          file: file,
          expire_at: Ci::PipelineArtifact::EXPIRATION_DATE.from_now
        )
      end

      private

      def build_carrierwave_file(pipeline)
        CarrierWaveStringFile.new_file(
          file_content: pipeline.coverage_reports.to_json,
          filename: Ci::PipelineArtifact::DEFAULT_FILE_NAMES.fetch(:code_coverage),
          content_type: 'application/json'
        )
      end
    end
  end
end
