# frozen_string_literal: true

module Projects
  module Ml
    class ModelsController < ::Projects::ApplicationController
      before_action :authorize_read_model_registry!
      before_action :authorize_write_model_registry!, only: [:destroy]
      before_action :set_model, only: [:show, :destroy]
      feature_category :mlops

      MAX_MODELS_PER_PAGE = 20

      def index
        find_params = params
                        .transform_keys(&:underscore)
                        .permit(:name, :order_by, :sort)

        finder = ::Projects::Ml::ModelFinder.new(@project, find_params)

        @paginator = finder.execute.keyset_paginate(cursor: params[:cursor], per_page: MAX_MODELS_PER_PAGE)

        @model_count = finder.count
      end

      def show; end

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
        @model = ::Ml::Model.by_project_id_and_id(@project, params[:model_id])

        render_404 unless @model
      end
    end
  end
end
