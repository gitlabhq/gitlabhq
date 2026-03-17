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
        stage.play_manual(current_user)

        respond_to do |format|
          format.json do
            head :no_content
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
