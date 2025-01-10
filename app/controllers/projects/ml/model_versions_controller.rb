# frozen_string_literal: true

module Projects
  module Ml
    class ModelVersionsController < ::Projects::ApplicationController
      feature_category :mlops
      before_action :authorize_read_model_registry!
      before_action :authorize_write_model_registry!, only: [:new, :edit]
      before_action :set_model_version, only: [:show, :edit]

      def show; end

      def edit; end

      def new
        @model = ::Ml::Model.by_project_id_and_id(@project, safe_params[:model_model_id])

        render_404 unless @model
      end

      private

      def authorize_read_model_registry!
        render_404 unless can?(current_user, :read_model_registry, @project)
      end

      def authorize_write_model_registry!
        render_404 unless can?(current_user, :write_model_registry, @project)
      end

      def set_model_version
        @model_version = ::Ml::ModelVersion.by_project_id_and_id(@project, safe_params[:model_version_id])

        return render_404 unless @model_version

        @model = @model_version.model
      end

      def safe_params
        params.permit(:model_model_id, :model_version_id)
      end
    end
  end
end
