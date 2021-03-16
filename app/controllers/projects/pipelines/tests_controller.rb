# frozen_string_literal: true

module Projects
  module Pipelines
    class TestsController < Projects::Pipelines::ApplicationController
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
            render json: TestSuiteSerializer
              .new(project: project, current_user: @current_user)
              .represent(test_suite, details: true)
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
        suite = builds.map do |build|
          build.collect_test_reports!(Gitlab::Ci::Reports::TestReports.new)
        end.sum

        Gitlab::Ci::Reports::TestFailureHistory.new(suite.failed.values, project).load!

        suite
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
