# frozen_string_literal: true

module Ci
  class RunnerNamespace < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :runner, inverse_of: :runner_namespaces, validate: true
    belongs_to :namespace, inverse_of: :runner_namespaces, class_name: '::Namespace'
    belongs_to :group, class_name: '::Group', foreign_key: :namespace_id

    validates :runner_id, uniqueness: { scope: :namespace_id }
  end
end
