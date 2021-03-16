# frozen_string_literal: true

module Ci
  class RunnerNamespace < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :runner, inverse_of: :runner_namespaces
    belongs_to :namespace, inverse_of: :runner_namespaces, class_name: '::Namespace'
    belongs_to :group, class_name: '::Group', foreign_key: :namespace_id

    validates :runner_id, uniqueness: { scope: :namespace_id }
    validate :group_runner_type

    private

    def group_runner_type
      errors.add(:runner, 'is not a group runner') unless runner&.group_type?
    end
  end
end
