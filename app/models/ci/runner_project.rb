# frozen_string_literal: true

module Ci
  class RunnerProject < ApplicationRecord
    extend Gitlab::Ci::Model
    include Limitable

    self.limit_name = 'ci_registered_project_runners'
    self.limit_scope = :project
    self.limit_feature_flag = :ci_runner_limits

    belongs_to :runner, inverse_of: :runner_projects
    belongs_to :project, inverse_of: :runner_projects

    validates :runner_id, uniqueness: { scope: :project_id }
  end
end
