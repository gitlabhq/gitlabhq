# frozen_string_literal: true

module Projects
  module Pipelines
    class TestsController < Projects::Pipelines::ApplicationController
      urgency :low, [:show, :summary]

      before_action :authorize_read_build!
      before_action :builds, only: [:show]

      feature_category :code_testing

      def summary
        respond_to do |format|
          format.json do
            render json: TestReportSummarySerializer
              .new(project: project, current_user: @current_user)
              .represent(pipeline.test_report_summary)
          end
        end
      end

      def show
        respond_to do |format|
          format.json do
            if Feature.enabled?(:ci_test_report_artifacts_expired, project, default_enabled: :yaml) && pipeline.has_expired_test_reports?
              render json: { errors: 'Test report artifacts have expired' }, status: :not_found
            else
              render json: TestSuiteSerializer
                .new(project: project, current_user: @current_user)
                .represent(test_suite, details: true)
            end
          end
        end
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def builds
        @builds ||= pipeline.latest_builds.id_in(build_ids).presence || render_404
      end

      def build_ids
        return [] unless params[:build_ids]

        params[:build_ids].split(",")
      end

      def test_suite
        suite = builds.sum do |build|
          build.collect_test_reports!(Gitlab::Ci::Reports::TestReports.new)
        end

        Gitlab::Ci::Reports::TestFailureHistory.new(suite.failed.values, project).load!

        suite
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
