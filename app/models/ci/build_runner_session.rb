module Ci
  # The purpose of this class is to store Build related runner session.
  # Data will be removed after transitioning from running to any state.
  class BuildRunnerSession < ActiveRecord::Base
    extend Gitlab::Ci::Model

    self.table_name = 'ci_builds_runner_session'

    belongs_to :build, class_name: 'Ci::Build'

    validates :build, presence: true
    validates :url, url: { protocols: %w(ws) }
  end
end
