# frozen_string_literal: true

module Projects
  module Ml
    class ExperimentsController < ::Projects::ApplicationController
      include Projects::Ml::ExperimentsHelper

      before_action :check_read, only: [:show, :index]
      before_action :check_write, only: [:destroy]
      before_action :set_experiment, only: [:show, :destroy]

      feature_category :mlops

      MAX_EXPERIMENTS_PER_PAGE = 20
      MAX_CANDIDATES_PER_PAGE = 30

      def index
        paginator = Projects::Ml::ExperimentFinder
          .new(@project, { with_candidate_count: true })
          .execute
          .keyset_paginate(cursor: params[:cursor], per_page: MAX_EXPERIMENTS_PER_PAGE)

        @experiments = paginator.records
        @page_info = page_info(paginator)
      end

      def show
        find_params = params
                        .transform_keys(&:underscore)
                        .permit(:name, :order_by, :sort, :order_by_type)

        finder = CandidateFinder.new(@experiment, find_params)

        respond_to do |format|
          format.csv do
            csv_data = ::Ml::CandidatesCsvPresenter.new(finder.execute).present

            send_data(csv_data, type: 'text/csv; charset=utf-8', filename: 'candidates.csv')
          end

          format.html do
            paginator = finder.execute.keyset_paginate(cursor: params[:cursor], per_page: MAX_CANDIDATES_PER_PAGE)

            @candidates = paginator.records
            @page_info = page_info(paginator)
          end
        end
      end

      def destroy
        @experiment.destroy

        redirect_to project_ml_experiments_path(@project),
          status: :found,
          notice: s_("MlExperimentTracking|Experiment removed")
      end

      private

      def check_read
        render_404 unless can?(current_user, :read_model_experiments, @project)
      end

      def check_write
        render_404 unless can?(current_user, :write_model_experiments, @project)
      end

      def set_experiment
        @experiment = ::Ml::Experiment.by_project_id_and_iid(@project.id, params[:iid])

        render_404 unless @experiment
      end
    end
  end
end
