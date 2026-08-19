# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class CoverageReportGenerator
        include Gitlab::Utils::StrongMemoize

        def initialize(pipeline)
          @pipeline = pipeline
        end

        def report
          coverage_report = Gitlab::Ci::Reports::CoverageReport.new

          # Return an empty report if the pipeline is a child pipeline.
          # Since the coverage report is used in a merge request report,
          # we are only interested in the coverage report from the root pipeline.
          return coverage_report if @pipeline.child?

          return coverage_report if merge_request_file_paths.empty?

          coverage_report.tap do |coverage_report|
            report_builds.find_each do |build|
              build.each_report(::Ci::JobArtifact.file_types_for_report(:coverage)) do |file_type, blob|
                # Parse into a scratch report so a report that fails mid-parse
                # contributes nothing instead of leaking partial data.
                blob_report = Gitlab::Ci::Reports::CoverageReport.new

                Gitlab::Ci::Parsers.fabricate!(file_type).parse!(
                  blob,
                  blob_report,
                  project_path: @pipeline.project.full_path,
                  worktree_paths: @pipeline.all_worktree_paths,
                  merge_request_paths: merge_request_file_paths,
                  project: @pipeline.project
                )

                blob_report.files.each { |filename, lines| coverage_report.add_file(filename, lines) }
              rescue Gitlab::Ci::Parsers::ParserError => e
                # A malformed report from one build should not discard
                # valid coverage from the rest of the pipeline.
                Gitlab::AppLogger.warn(
                  Labkit::Fields::CLASS_NAME => self.class.name,
                  Labkit::Fields::ERROR_TYPE => e.class.name,
                  Labkit::Fields::ERROR_MESSAGE => e.message,
                  message: 'Failed to parse coverage report artifact',
                  Labkit::Fields::GL_PIPELINE_ID => @pipeline.id,
                  build_id: build.id
                )
              end
            end
          end
        end

        private

        def report_builds
          @pipeline.latest_report_builds_in_self_and_project_descendants(::Ci::JobArtifact.of_report_type(:coverage))
        end

        def merge_request_file_paths
          merge_request_paths = Set.new

          @pipeline.merge_requests_as_head_pipeline.each do |merge_request|
            merge_request_paths += merge_request.modified_paths
          end

          merge_request_paths
        end
        strong_memoize_attr :merge_request_file_paths
      end
    end
  end
end
