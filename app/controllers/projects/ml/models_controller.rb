# frozen_string_literal: true

module Projects
  module Ml
    class ModelsController < ::Projects::ApplicationController
      before_action :authorize_read_model_registry!
      before_action :authorize_write_model_registry!, only: [:destroy, :new, :edit]
      before_action :set_model, only: [:show, :destroy, :edit]
      feature_category :mlops

      MAX_MODELS_PER_PAGE = 20

      def index; end

      def new; end

      def show; end

      def edit; end

      def destroy
        @model.destroy!

        redirect_to project_ml_models_path(@project),
          status: :found,
          notice: s_("MlExperimentTracking|Model removed")
      end

      private

      def authorize_read_model_registry!
        render_404 unless can?(current_user, :read_model_registry, @project)
      end

      def authorize_write_model_registry!
        render_404 unless can?(current_user, :write_model_registry, @project)
      end

      def set_model
        @model = ::Ml::Model.by_project_id_and_id(@project, params.permit(:model_id)[:model_id])

        render_404 unless @model
      end
    end
  end
end
