# frozen_string_literal: true

module Projects
  module Ml
    class CandidatesController < ApplicationController
      before_action :set_candidate
      before_action :check_read, only: [:show]
      before_action :check_write, only: [:destroy, :promote]

      feature_category :mlops

      def show; end

      def promote; end

      def destroy
        @experiment = @candidate.experiment
        @candidate.destroy!

        redirect_to project_ml_experiment_path(@project, @experiment.iid),
          status: :found,
          notice: s_("MlExperimentTracking|Run removed")
      end

      private

      def set_candidate
        @candidate = ::Ml::Candidate.with_project_id_and_iid(@project.id, params.permit(:iid)[:iid])

        render_404 unless @candidate.present?
      end

      def check_read
        render_404 unless can?(current_user, :read_model_experiments, @project)
      end

      def check_write
        render_404 unless can?(current_user, :write_model_experiments, @project)
      end
    end
  end
end
