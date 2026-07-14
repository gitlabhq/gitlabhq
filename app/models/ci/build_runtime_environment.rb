# frozen_string_literal: true

module Ci
  # Read more https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/2f8156f76b80d344b6b0c6c06332b40aa446068b/content/handbook/engineering/architecture/design-documents/runner_suspendable_environments/_index.md?plain=1#L69
  class BuildRuntimeEnvironment < Ci::ApplicationRecord
    include Ci::Partitionable

    self.table_name = :ci_build_runtime_environments
    self.primary_key = :build_id

    query_constraints :build_id, :partition_id
    partitionable scope: :build

    before_validation :ensure_project_id, on: :create

    belongs_to :build,
      class_name: 'Ci::Build',
      foreign_key: [:build_id, :partition_id],
      inverse_of: :build_runtime_environment
    belongs_to :runtime_environment, optional: true, class_name: 'Ci::RuntimeEnvironment',
      inverse_of: :build_runtime_environments
    belongs_to :runner_manager, foreign_key: :runner_machine_id, class_name: 'Ci::RunnerManager',
      inverse_of: :build_runtime_environments, optional: true

    validates :build, presence: true
    validates :project_id, presence: true

    private

    def ensure_project_id
      self.project_id ||= build&.project_id
    end
  end
end
