# frozen_string_literal: true

module Projects
  module Ml
    class ModelsController < ::Projects::ApplicationController
      before_action :check_feature_enabled
      before_action :set_model, only: [:show]
      feature_category :mlops

      MAX_MODELS_PER_PAGE = 20

      def index
        @paginator = ::Projects::Ml::ModelFinder.new(@project)
                                                .execute
                                                .keyset_paginate(cursor: params[:cursor], per_page: MAX_MODELS_PER_PAGE)
      end

      def show; end

      private

      def check_feature_enabled
        render_404 unless can?(current_user, :read_model_registry, @project)
      end

      def set_model
        @model = ::Ml::Model.by_project_id_and_id(@project, params[:model_id])

        render_404 unless @model
      end
    end
  end
end
