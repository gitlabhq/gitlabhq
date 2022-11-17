# frozen_string_literal: true

module Ml
  class Candidate < ApplicationRecord
    enum status: { running: 0, scheduled: 1, finished: 2, failed: 3, killed: 4 }

    validates :iid, :experiment, presence: true
    validates :status, inclusion: { in: statuses.keys }

    belongs_to :experiment, class_name: 'Ml::Experiment'
    belongs_to :user
    has_many :metrics, class_name: 'Ml::CandidateMetric'
    has_many :params, class_name: 'Ml::CandidateParam'
    has_many :latest_metrics, -> { latest }, class_name: 'Ml::CandidateMetric', inverse_of: :candidate

    attribute :iid, default: -> { SecureRandom.uuid }

    scope :including_metrics_and_params, -> { includes(:latest_metrics, :params) }

    def artifact_root
      "/ml_candidate_#{iid}/-/"
    end

    class << self
      def with_project_id_and_iid(project_id, iid)
        return unless project_id.present? && iid.present?

        joins(:experiment).find_by(experiment: { project_id: project_id }, iid: iid)
      end
    end
  end
end
