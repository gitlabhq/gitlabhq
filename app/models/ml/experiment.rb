# frozen_string_literal: true

module Ml
  class Experiment < ApplicationRecord
    include AtomicInternalId

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
    end
  end
end
