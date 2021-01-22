# frozen_string_literal: true
module Ci
  module PipelineArtifacts
    class CreateQualityReportService
      def execute(pipeline)
        return unless pipeline.can_generate_codequality_reports?
        return if pipeline.has_codequality_reports?

        file = build_carrierwave_file(pipeline)

        pipeline.pipeline_artifacts.create!(
          project_id: pipeline.project_id,
          file_type: :code_quality,
          file_format: :raw,
          size: file["tempfile"].size,
          file: file,
          expire_at: Ci::PipelineArtifact::EXPIRATION_DATE.from_now
        )
      end

      private

      def build_carrierwave_file(pipeline)
        CarrierWaveStringFile.new_file(
          file_content: pipeline.codequality_reports.to_json,
          filename: Ci::PipelineArtifact::DEFAULT_FILE_NAMES.fetch(:code_quality),
          content_type: 'application/json'
        )
      end
    end
  end
end
