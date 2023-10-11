# frozen_string_literal: true

module Projects
  module Ml
    class ModelsController < ::Projects::ApplicationController
      before_action :check_feature_enabled
      feature_category :mlops

      MAX_MODELS_PER_PAGE = 20

      def index
        @paginator = ::Projects::Ml::ModelFinder.new(@project)
                                                .execute
                                                .keyset_paginate(cursor: params[:cursor], per_page: MAX_MODELS_PER_PAGE)
      end

      private

      def check_feature_enabled
        render_404 unless can?(current_user, :read_model_registry, @project)
      end
    end
  end
end
