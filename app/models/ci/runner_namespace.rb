# frozen_string_literal: true

module Ci
  class RunnerNamespace < ApplicationRecord
    extend Gitlab::Ci::Model
    include Limitable

    self.limit_name = 'ci_registered_group_runners'
    self.limit_scope = :group
    self.limit_relation = :recent_runners
    self.limit_feature_flag = :ci_runner_limits

    belongs_to :runner, inverse_of: :runner_namespaces
    belongs_to :namespace, inverse_of: :runner_namespaces, class_name: '::Namespace'
    belongs_to :group, class_name: '::Group', foreign_key: :namespace_id

    validates :runner_id, uniqueness: { scope: :namespace_id }
    validate :group_runner_type

    def recent_runners
      ::Ci::Runner.belonging_to_group(namespace_id).recent
    end

    private

    def group_runner_type
      errors.add(:runner, 'is not a group runner') unless runner&.group_type?
    end
  end
end
