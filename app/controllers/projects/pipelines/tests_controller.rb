# frozen_string_literal: true

module Projects
  module Pipelines
    class TestsController < Projects::ApplicationController
      before_action :pipeline
      before_action :authorize_read_pipeline!
      before_action :authorize_read_build!
      before_action :validate_feature_flag!

      def summary
        respond_to do |format|
          format.json do
            render json: TestReportSerializer
              .new(project: project, current_user: @current_user)
              .represent(pipeline.test_report_summary)
          end
        end
      end

      private

      def validate_feature_flag!
        render_404 unless Feature.enabled?(:build_report_summary, project)
      end

      def pipeline
        project.all_pipelines.find(tests_params[:id])
      end

      def tests_params
        params.permit(:id)
      end
    end
  end
end
