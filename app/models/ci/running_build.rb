# frozen_string_literal: true

module Ci
  class RunningBuild < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build'
    belongs_to :runner, class_name: 'Ci::Runner'

    enum runner_type: ::Ci::Runner.runner_types

    def self.upsert_shared_runner_build!(build)
      unless build.shared_runner_build?
        raise ArgumentError, 'build has not been picked by a shared runner'
      end

      entry = self.new(build: build,
                       project: build.project,
                       runner: build.runner,
                       runner_type: build.runner.runner_type)

      entry.validate!

      self.upsert(entry.attributes.compact, returning: %w[build_id], unique_by: :build_id)
    end
  end
end
