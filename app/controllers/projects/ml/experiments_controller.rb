# frozen_string_literal: true

module Projects
  module Ml
    class ExperimentsController < ::Projects::ApplicationController
      before_action :check_feature_flag

      feature_category :mlops

      MAX_PER_PAGE = 20

      def index
        @experiments = ::Ml::Experiment.by_project_id(@project.id).page(params[:page]).per(MAX_PER_PAGE)
      end

      def show
        @experiment = ::Ml::Experiment.by_project_id_and_iid(@project.id, params[:id])

        return redirect_to project_ml_experiments_path(@project) unless @experiment.present?

        @candidates = @experiment.candidates&.including_metrics_and_params
        @candidates.each(&:artifact_lazy)
      end

      private

      def check_feature_flag
        render_404 unless Feature.enabled?(:ml_experiment_tracking, @project)
      end
    end
  end
end
