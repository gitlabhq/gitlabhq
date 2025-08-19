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

    def self.existing_project_ids(project_ids)
      return [] if project_ids.empty?

      project_ids = project_ids.map { |id| [id] }
      from_sql = Arel::Nodes::Grouping.new(Arel::Nodes::ValuesList.new(project_ids)).as('list (project_id)').to_sql

      from(from_sql)
        .where_exists(Ci::RunnerProject.where('project_id = list.project_id'))
        .pluck(:project_id) # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- project_ids is already batched in User#ci_available_project_runners.
    end

    def recent_runners
      ::Ci::Runner.belonging_to_project(project_id).recent
    end

    validates :runner, presence: true
    validates :runner_id, uniqueness: { scope: :project_id }
    validates :project, presence: true
  end
end
