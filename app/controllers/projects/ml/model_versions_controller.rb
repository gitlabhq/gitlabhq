# frozen_string_literal: true

module Projects
  module Ml
    class ModelVersionsController < ::Projects::ApplicationController
      before_action :authorize_read_model_registry!
      feature_category :mlops

      def show
        @model_version = ::Ml::ModelVersion.by_project_id_and_id(@project, params[:model_version_id])

        return render_404 unless @model_version

        @model = @model_version.model
      end

      def new
        @model = ::Ml::Model.by_project_id_and_id(@project, params[:model_model_id])

        render_404 unless @model
      end

      private

      def authorize_read_model_registry!
        render_404 unless can?(current_user, :read_model_registry, @project)
      end
    end
  end
end
