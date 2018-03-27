module Ci
  class RunnerProject < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :runner
    belongs_to :project

    validates :runner_id, uniqueness: { scope: :project_id }
  end
end
