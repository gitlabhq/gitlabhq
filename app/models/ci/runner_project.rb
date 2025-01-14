# frozen_string_literal: true

module Ci
  class RunnerProject < Ci::ApplicationRecord
    include EachBatch
    include Limitable

    self.limit_name = 'ci_registered_project_runners'
    self.limit_scope = :project
    self.limit_relation = :recent_runners

    belongs_to :runner, inverse_of: :runner_projects
    belongs_to :project, inverse_of: :runner_projects

    scope :belonging_to_project, ->(project) { where(project_id: project) }

    def recent_runners
      ::Ci::Runner.belonging_to_project(project_id).recent
    end

    validates :runner, presence: true
    validates :runner_id, uniqueness: { scope: :project_id }
    validates :project, presence: true
  end
end
