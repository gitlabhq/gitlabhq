# frozen_string_literal: true

module Ml
  class Candidate < ApplicationRecord
    PACKAGE_PREFIX = 'ml_candidate_'

    enum status: { running: 0, scheduled: 1, finished: 2, failed: 3, killed: 4 }

    validates :iid, :experiment, presence: true
    validates :status, inclusion: { in: statuses.keys }

    belongs_to :experiment, class_name: 'Ml::Experiment'
    belongs_to :user
    has_many :metrics, class_name: 'Ml::CandidateMetric'
    has_many :params, class_name: 'Ml::CandidateParam'
    has_many :metadata, class_name: 'Ml::CandidateMetadata'
    has_many :latest_metrics, -> { latest }, class_name: 'Ml::CandidateMetric', inverse_of: :candidate

    attribute :iid, default: -> { SecureRandom.uuid }

    scope :including_relationships, -> { includes(:latest_metrics, :params, :user) }

    delegate :project_id, :project, to: :experiment

    def artifact_root
      "/#{package_name}/#{package_version}/"
    end

    def artifact
      artifact_lazy&.itself
    end

    def artifact_lazy
      BatchLoader.for(id).batch do |candidate_ids, loader|
        Packages::Package
          .joins("INNER JOIN ml_candidates ON packages_packages.name=(concat('#{PACKAGE_PREFIX}', ml_candidates.id))")
          .where(ml_candidates: { id: candidate_ids })
          .find_each do |package|
            loader.call(package.name.delete_prefix(PACKAGE_PREFIX).to_i, package)
          end
      end
    end

    def package_name
      "#{PACKAGE_PREFIX}#{id}"
    end

    def package_version
      '-'
    end

    class << self
      def with_project_id_and_iid(project_id, iid)
        return unless project_id.present? && iid.present?

        joins(:experiment).find_by(experiment: { project_id: project_id }, iid: iid)
      end
    end
  end
end
