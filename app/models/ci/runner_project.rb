module Ci
  class RunnerProject < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :runner, inverse_of: :runner_projects
    belongs_to :project, inverse_of: :runner_projects

    validates :runner_id, uniqueness: { scope: :project_id }
  end
end
