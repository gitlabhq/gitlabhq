# frozen_string_literal: true

# Abstract class encapsulating common logic for creating new controllers in a pipeline context

module Projects
  module Pipelines
    class ApplicationController < Projects::ApplicationController
      include Gitlab::Utils::StrongMemoize

      before_action :pipeline
      before_action :authorize_read_pipeline!

      feature_category :continuous_integration
      urgency :low

      private

      def pipeline
        strong_memoize(:pipeline) do
          project.all_pipelines.find(params[:pipeline_id]).tap do |pipeline|
            render_404 unless can?(current_user, :read_pipeline, pipeline)
          end
        end
      end
    end
  end
end
