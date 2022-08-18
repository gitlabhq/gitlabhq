# frozen_string_literal: true

module Projects
  module Pipelines
    class StagesController < Projects::Pipelines::ApplicationController
      before_action :authorize_update_pipeline!
      before_action :stage, only: [:play_manual]

      urgency :low, [
        :play_manual
      ]

      def play_manual
        ::Ci::PlayManualStageService
          .new(@project, current_user, pipeline: pipeline)
          .execute(stage)

        respond_to do |format|
          format.json do
            render json: StageSerializer
              .new(project: @project, current_user: @current_user)
              .represent(stage)
          end
        end
      end

      private

      def stage
        @stage ||= pipeline.stage(params[:stage_name]).presence || render_404
      end
    end
  end
end
