# frozen_string_literal: true

module Projects
  module Ml
    class CandidatesController < ApplicationController
      before_action :check_feature_flag, :set_candidate

      feature_category :mlops

      def show; end

      def destroy
        @experiment = @candidate.experiment
        @candidate.destroy!

        redirect_to project_ml_experiment_path(@project, @experiment.iid),
          status: :found,
          notice: s_("MlExperimentTracking|Candidate removed")
      end

      private

      def set_candidate
        @candidate = ::Ml::Candidate.with_project_id_and_iid(@project.id, params['iid'])

        render_404 unless @candidate.present?
      end

      def check_feature_flag
        render_404 unless Feature.enabled?(:ml_experiment_tracking, @project)
      end
    end
  end
end
