# frozen_string_literal: true

module Ci
  class RunnerProject < Ci::ApplicationRecord
    include Limitable

    self.limit_name = 'ci_registered_project_runners'
    self.limit_scope = :project
    self.limit_relation = :recent_runners

    belongs_to :runner, inverse_of: :runner_projects
    belongs_to :project, inverse_of: :runner_projects

    def recent_runners
      ::Ci::Runner.belonging_to_project(project_id).recent
    end

    validates :runner, presence: true
    validates :runner_id, uniqueness: { scope: :project_id }
    # NOTE: `on:` hook can be removed the milestone after https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155760
    # is merged
    validates :project, presence: true, on: [:create, :update]
  end
end
