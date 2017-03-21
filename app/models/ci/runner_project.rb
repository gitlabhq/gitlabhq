module Ci
  class RunnerProject < ActiveRecord::Base
    extend Ci::Model

    belongs_to :runner
    belongs_to :project

    validates :runner_id, uniqueness: { scope: :project_id }

    after_save :tick_runner_queue

    delegate :tick_runner_queue, to: :runner, allow_nil: true
  end
end
