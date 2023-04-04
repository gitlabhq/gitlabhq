# frozen_string_literal: true

module Ml
  class Experiment < ApplicationRecord
    include AtomicInternalId

    PACKAGE_PREFIX = 'ml_experiment_'

    validates :name, :project, presence: true
    validates :name, uniqueness: { scope: :project, message: "should be unique in the project" }

    belongs_to :project
    belongs_to :user
    has_many :candidates, class_name: 'Ml::Candidate'
    has_many :metadata, class_name: 'Ml::ExperimentMetadata'

    scope :with_candidate_count, -> {
      left_outer_joins(:candidates)
        .select("ml_experiments.*, count(ml_candidates.id) as candidate_count")
        .group(:id)
    }

    has_internal_id :iid, scope: :project

    def package_name
      "#{PACKAGE_PREFIX}#{iid}"
    end

    class << self
      def by_project_id_and_iid(project_id, iid)
        find_by(project_id: project_id, iid: iid)
      end

      def by_project_id_and_name(project_id, name)
        find_by(project_id: project_id, name: name)
      end

      def by_project_id(project_id)
        where(project_id: project_id).order(id: :desc)
      end

      def package_for_experiment?(package_name)
        return false unless package_name&.starts_with?(PACKAGE_PREFIX)

        iid = package_name.delete_prefix(PACKAGE_PREFIX)

        numeric?(iid)
      end

      private

      def numeric?(value)
        value.match?(/\A\d+\z/)
      end
    end
  end
end
