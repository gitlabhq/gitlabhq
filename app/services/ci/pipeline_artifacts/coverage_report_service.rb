# frozen_string_literal: true
module Ci
  module PipelineArtifacts
    class CoverageReportService
      include Gitlab::Utils::StrongMemoize

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        return if pipeline.has_coverage_reports?
        return if report.empty?

        pipeline.pipeline_artifacts.create!(
          project_id: pipeline.project_id,
          file_type: :code_coverage,
          file_format: Ci::PipelineArtifact::REPORT_TYPES.fetch(:code_coverage),
          size: carrierwave_file["tempfile"].size,
          file: carrierwave_file,
          expire_at: Ci::PipelineArtifact::EXPIRATION_DATE.from_now
        )
      end

      private

      attr_reader :pipeline

      def report
        strong_memoize(:report) do
          Gitlab::Ci::Reports::CoverageReportGenerator.new(pipeline).report
        end
      end

      def carrierwave_file
        strong_memoize(:carrier_wave_file) do
          CarrierWaveStringFile.new_file(
            file_content: report.to_json,
            filename: Ci::PipelineArtifact::DEFAULT_FILE_NAMES.fetch(:code_coverage),
            content_type: 'application/json'
          )
        end
      end
    end
  end
end
