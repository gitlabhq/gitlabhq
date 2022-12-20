# frozen_string_literal: true

module Projects
  module Ml
    class CandidatesController < ApplicationController
      before_action :check_feature_flag

      feature_category :mlops

      def show
        @candidate = ::Ml::Candidate.with_project_id_and_iid(@project.id, params['iid'])

        render_404 unless @candidate.present?
      end

      private

      def check_feature_flag
        render_404 unless Feature.enabled?(:ml_experiment_tracking, @project)
      end
    end
  end
end
