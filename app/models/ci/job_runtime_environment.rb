# frozen_string_literal: true

module Ci
  # Read more https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/2f8156f76b80d344b6b0c6c06332b40aa446068b/content/handbook/engineering/architecture/design-documents/runner_suspendable_environments/_index.md?plain=1#L69
  class JobRuntimeEnvironment < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :p_ci_job_runtime_environments
    self.primary_key = :build_id

    query_constraints :build_id, :partition_id
    partitionable scope: :build, partitioned: true

    before_validation :ensure_project_id, on: :create

    belongs_to :build,
      class_name: 'Ci::Build',
      foreign_key: [:build_id, :partition_id],
      inverse_of: :job_runtime_environment
    belongs_to :runtime_environment, optional: true, class_name: 'Ci::RuntimeEnvironment',
      inverse_of: :job_runtime_environments
    belongs_to :runner_manager, foreign_key: :runner_machine_id, class_name: 'Ci::RunnerManager',
      inverse_of: :job_runtime_environments, optional: true

    validates :build, presence: true
    validates :project_id, presence: true

    def self.runner_machine_id_for(build)
      return unless ::Feature.enabled?(:ci_suspendable_environment_runner_routing, build.project,
        type: :gitlab_com_derisk)

      runtime_environment_id = build.job_runtime_environment&.runtime_environment_id
      return unless runtime_environment_id

      in_partition(Ci::Partition.recent_ids)
        .where(runtime_environment_id: runtime_environment_id)
        .where.not(runner_machine_id: nil)
        .order(build_id: :asc)
        .pick(:runner_machine_id)
    end

    private

    def ensure_project_id
      self.project_id ||= build&.project_id
    end
  end
end
