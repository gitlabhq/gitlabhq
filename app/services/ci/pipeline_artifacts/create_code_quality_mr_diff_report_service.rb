# frozen_string_literal: true
module Ci
  module PipelineArtifacts
    class CreateCodeQualityMrDiffReportService
      include Gitlab::Utils::StrongMemoize

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        return unless pipeline.can_generate_codequality_reports?
        return if pipeline.has_codequality_mr_diff_report?
        return unless new_errors_introduced?

        Ci::PipelineArtifact.create_or_replace_for_pipeline!(**artifact_attributes)
      end

      private

      attr_reader :pipeline

      def artifact_attributes
        file = build_carrierwave_file!

        {
          pipeline: pipeline,
          file_type: :code_quality_mr_diff,
          size: file["tempfile"].size,
          file: file,
          locked: pipeline.locked
        }
      end

      def merge_requests
        strong_memoize(:merge_requests) do
          pipeline.merge_requests_as_head_pipeline
        end
      end

      def head_report
        strong_memoize(:head_report) do
          pipeline.codequality_reports
        end
      end

      def base_report(merge_request)
        strong_memoize(:base_report) do
          merge_request&.base_pipeline&.codequality_reports
        end
      end

      def mr_diff_report_by_merge_requests
        strong_memoize(:mr_diff_report_by_merge_requests) do
          merge_requests.each_with_object({}) do |merge_request, hash|
            key = "merge_request_#{merge_request.id}"
            new_errors = Gitlab::Ci::Reports::CodequalityReportsComparer.new(base_report(merge_request), head_report).new_errors
            next if new_errors.empty?

            hash[key] = Gitlab::Ci::Reports::CodequalityMrDiff.new(new_errors)
          end
        end
      end

      def new_errors_introduced?
        mr_diff_report_by_merge_requests.present?
      end

      def build_carrierwave_file!
        CarrierWaveStringFile.new_file(
          file_content: build_quality_mr_diff_report(mr_diff_report_by_merge_requests),
          filename: Ci::PipelineArtifact::DEFAULT_FILE_NAMES.fetch(:code_quality_mr_diff),
          content_type: 'application/json'
        )
      end

      def build_quality_mr_diff_report(mr_diff_report)
        Gitlab::Json.dump(mr_diff_report.each_with_object({}) do |diff_report, hash|
          hash[diff_report.first] = Ci::CodequalityMrDiffReportSerializer.new.represent(diff_report.second) # rubocop: disable CodeReuse/Serializer
        end)
      end
    end
  end
end
