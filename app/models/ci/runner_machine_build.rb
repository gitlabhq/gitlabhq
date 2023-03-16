# frozen_string_literal: true

module Ci
  class RunnerMachineBuild < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_runner_machine_builds
    self.primary_key = :build_id

    partitionable scope: :build, partitioned: true

    belongs_to :build, inverse_of: :runner_machine_build, class_name: 'Ci::Build'
    belongs_to :runner_machine, inverse_of: :runner_machine_builds, class_name: 'Ci::RunnerMachine'

    validates :build, presence: true
    validates :runner_machine, presence: true

    scope :for_build, ->(build_id) { where(build_id: build_id) }

    def self.pluck_build_id_and_runner_machine_id
      select(:build_id, :runner_machine_id)
        .pluck(:build_id, :runner_machine_id)
        .to_h
    end
  end
end
