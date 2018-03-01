module Ci
  class BuildMetadata < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include Presentable
    include ChronicDurationAttribute

    self.table_name = 'ci_builds_metadata'

    belongs_to :build, class_name: 'Ci::Build'

    chronic_duration_attr_reader :used_timeout_human_readable, :used_timeout

    enum timeout_source: {
        unknown_timeout_source: nil,
        project_timeout_source: 1,
        runner_timeout_source: 2
    }

    def save_timeout_state!
      self.used_timeout = build.timeout
      self.timeout_source = build.timeout < build.project.build_timeout ? :runner_timeout_source : :project_timeout_source
      save!
    end
  end
end
