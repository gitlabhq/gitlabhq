# frozen_string_literal: true

module Projects
  module Pipelines
    class TestsController < Projects::Pipelines::ApplicationController
      urgency :low, [:show, :summary]

      before_action :authorize_read_build!
      before_action :validate_test_reports!, only: [:show]
      before_action :check_requested_builds!, only: [:show]

      feature_category :code_testing

      def summary
        respond_to do |format|
          format.json do
            render json: TestReportSummarySerializer
              .new(project: project, current_user: @current_user)
              .represent(pipeline.accessible_test_report_summary(current_user))
          end
        end
      end

      def show
        respond_to do |format|
          format.json do
            render json: TestSuiteSerializer
              .new(project: project, current_user: @current_user)
              .represent(test_suite, details: true)
          end
        end
      end

      private

      def validate_test_reports!
        render json: { errors: 'Test report artifacts not found' }, status: :not_found unless pipeline.has_test_reports?
      end

      def check_requested_builds!
        render_404 unless builds.present?
      end

      def builds
        @builds ||= begin
          candidates = pipeline
            .latest_test_report_builds_in_self_and_project_descendants
            .id_in(build_ids)
            .to_a

          # Preload the user's access level across the builds' projects so the
          # per-artifact :read_job_artifacts check does not trigger a
          # project-authorizations query per build (multi-project hierarchies).
          if current_user
            ::Preloaders::UserMaxAccessLevelInProjectsPreloader
              .new(candidates.map(&:project).uniq, current_user)
              .execute
          end

          candidates.select { |build| build.test_report_readable_by?(current_user) }
        end
      end

      def build_ids
        ids = params.permit(:build_ids, build_ids: [])[:build_ids]
        return [] unless ids

        ids.is_a?(Array) ? ids : ids.split(",")
      end

      def test_suite
        suite = builds.sum(Gitlab::Ci::Reports::TestSuite.new) do |build|
          test_report = build.collect_test_reports!(Gitlab::Ci::Reports::TestReport.new)
          test_report.get_suite(build.test_suite_name)
        end

        Gitlab::Ci::Reports::TestFailureHistory.new(suite.failed.values, project).load!

        suite
      end
    end
  end
end
