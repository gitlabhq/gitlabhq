module Ci
  # The purpose of this class is to store Build related data that can be disposed.
  # Data that should be persisted forever, should be stored with Ci::Build model.
  class BuildMetadata < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include Presentable
    include ChronicDurationAttribute

    self.table_name = 'ci_builds_metadata'

    belongs_to :build, class_name: 'Ci::Build'

    chronic_duration_attr_reader :timeout_human_readable, :timeout

    enum timeout_source: {
        unknown_timeout_source: 1,
        project_timeout_source: 2,
        runner_timeout_source: 3
    }

    def save_timeout_state!
      project_timeout = build.project&.build_timeout
      timeout = [project_timeout, build.runner&.maximum_timeout].compact.min

      self.timeout = timeout
      self.timeout_source = timeout < project_timeout ? :runner_timeout_source : :project_timeout_source

      save!
    end
  end
end
