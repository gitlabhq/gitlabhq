# frozen_string_literal: true

module Ci
  class RunnerManagerBuild < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_runner_machine_builds
    self.primary_key = :build_id

    query_constraints :build_id, :partition_id
    partitionable scope: :build, partitioned: true

    alias_attribute :runner_manager_id, :runner_machine_id

    before_validation :ensure_project_id, on: :create

    belongs_to :build, inverse_of: :runner_manager_build, class_name: 'Ci::Build'
    belongs_to :runner_manager, foreign_key: :runner_machine_id, inverse_of: :runner_manager_builds,
      class_name: 'Ci::RunnerManager'

    validates :build, presence: true
    validates :runner_manager, presence: true
    validates :project_id, presence: true

    scope :for_build, ->(build_id) { where(build_id: build_id) }

    def self.pluck_build_id_and_runner_manager_id
      select(:build_id, :runner_manager_id)
        .pluck(:build_id, :runner_manager_id)
        .to_h
    end

    private

    def ensure_project_id
      self.project_id ||= build&.project_id
    end
  end
end
