# frozen_string_literal: true

module Ci
  # This model represents metadata for a running build.
  # Despite the generic RunningBuild name, in this first iteration it applies only to shared runners
  #   (see Ci::RunningBuild.upsert_shared_runner_build!).
  # The decision to insert all of the running builds here was deferred to avoid the pressure on the database as
  # at this time that was not necessary.
  # We can reconsider the decision to limit this only to shared runners when there is more evidence that inserting all
  # of the running builds there is worth the additional pressure.
  class RunningBuild < Ci::ApplicationRecord
    include Ci::Partitionable

    partitionable scope: :build

    belongs_to :project
    belongs_to :build, # rubocop: disable Rails/InverseOf -- this relation is not present on build
      ->(running_build) { in_partition(running_build) },
      class_name: 'Ci::Build',
      partition_foreign_key: :partition_id
    belongs_to :runner, class_name: 'Ci::Runner'

    enum runner_type: ::Ci::Runner.runner_types

    def self.upsert_shared_runner_build!(build)
      unless build.shared_runner_build?
        raise ArgumentError, 'build has not been picked by a shared runner'
      end

      entry = self.new(
        build: build,
        project: build.project,
        runner: build.runner,
        runner_type: build.runner.runner_type
      )

      entry.validate!

      self.upsert(entry.attributes.compact, returning: %w[build_id], unique_by: :build_id)
    end
  end
end
