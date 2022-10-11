# frozen_string_literal: true

module Ml
  module ExperimentTracking
    class CandidateRepository
      attr_accessor :project, :user, :experiment, :candidate

      def initialize(project, user)
        @project = project
        @user = user
      end

      def by_iid(iid)
        ::Ml::Candidate.with_project_id_and_iid(project.id, iid)
      end

      def create!(experiment, start_time)
        experiment.candidates.create!(
          user: user,
          start_time: start_time || 0
        )
      end

      def update(candidate, status, end_time)
        candidate.status = status.downcase if status
        candidate.end_time = end_time if end_time

        candidate.save
      end

      def add_metric!(candidate, name, value, tracked_at, step)
        candidate.metrics.create!(
          name: name,
          value: value,
          tracked_at: tracked_at,
          step: step
        )
      end

      def add_param!(candidate, name, value)
        candidate.params.create!(name: name, value: value)
      end

      def add_metrics(candidate, metric_definitions)
        return unless candidate.present?

        metrics = metric_definitions.map do |metric|
          {
            candidate_id: candidate.id,
            name: metric[:key],
            value: metric[:value],
            tracked_at: metric[:timestamp],
            step: metric[:step],
            **timestamps
          }
        end

        ::Ml::CandidateMetric.insert_all(metrics, returning: false) unless metrics.empty?
      end

      def add_params(candidate, param_definitions)
        return unless candidate.present?

        parameters = param_definitions.map do |p|
          {
            candidate_id: candidate.id,
            name: p[:key],
            value: p[:value],
            **timestamps
          }
        end

        ::Ml::CandidateParam.insert_all(parameters, returning: false) unless parameters.empty?
      end

      private

      def timestamps
        current_time = Time.zone.now

        { created_at: current_time, updated_at: current_time }
      end
    end
  end
end
