# frozen_string_literal: true

module Projects
  module Ml
    class ExperimentsController < ::Projects::ApplicationController
      include Projects::Ml::ExperimentsHelper

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

        find_params = params
                        .transform_keys(&:underscore)
                        .permit(:name, :order_by, :sort, :order_by_type)

        @candidates = CandidateFinder.new(@experiment, find_params).execute

        page = [params[:page].to_i, 1].max

        @candidates, @pagination_info = paginate_candidates(@candidates, page, MAX_CANDIDATES_PER_PAGE)

        return if @pagination_info[:total_pages] == 0

        redirect_to(url_for(safe_params.merge(page: @pagination_info[:total_pages]))) if @pagination_info[:out_of_range]

        @candidates.each(&:artifact_lazy)
      end

      private

      def check_feature_flag
        render_404 unless Feature.enabled?(:ml_experiment_tracking, @project)
      end
    end
  end
end
