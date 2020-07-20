# frozen_string_literal: true

module Projects
  module Pipelines
    class TestsController < Projects::Pipelines::ApplicationController
      before_action :validate_feature_flag!
      before_action :authorize_read_build!
      before_action :builds, only: [:show]

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

      def validate_feature_flag!
        render_404 unless Feature.enabled?(:build_report_summary, project)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def builds
        pipeline.latest_builds.where(id: build_params)
      end

      def build_params
        return [] unless params[:build_ids]

        params[:build_ids].split(",")
      end

      def test_suite
        if builds.present?
          builds.map do |build|
            build.collect_test_reports!(Gitlab::Ci::Reports::TestReports.new)
          end.sum
        else
          render_404
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
