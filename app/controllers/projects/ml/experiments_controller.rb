# frozen_string_literal: true

module Projects
  module Ml
    class ExperimentsController < ::Projects::ApplicationController
      before_action :check_feature_flag

      feature_category :mlops

      MAX_EXPERIMENTS_PER_PAGE = 20
      MAX_CANDIDATES_PER_PAGE = 30

      def index
        @experiments = ::Ml::Experiment.by_project_id(@project.id).page(params[:page]).per(MAX_EXPERIMENTS_PER_PAGE)
      end

      def show
        @experiment = ::Ml::Experiment.by_project_id_and_iid(@project.id, params[:id])

        return redirect_to project_ml_experiments_path(@project) unless @experiment.present?

        page = params[:page].to_i
        page = 1 if page == 0

        @candidates = @experiment.candidates
                                 .including_metrics_and_params
                                 .page(page)
                                 .per(MAX_CANDIDATES_PER_PAGE)

        return unless @candidates

        return redirect_to(url_for(page: @candidates.total_pages)) if @candidates.out_of_range?

        @pagination = {
          page: page,
          is_last_page: @candidates.last_page?,
          per_page: MAX_CANDIDATES_PER_PAGE,
          total_items: @candidates.total_count
        }

        @candidates.each(&:artifact_lazy)
      end

      private

      def check_feature_flag
        render_404 unless Feature.enabled?(:ml_experiment_tracking, @project)
      end
    end
  end
end
