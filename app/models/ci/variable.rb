# frozen_string_literal: true

module Ci
  class Variable < Ci::ApplicationRecord
    include Ci::HasVariable
    include Presentable
    include Ci::Maskable
    prepend HasEnvironmentScope

    belongs_to :project

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      scope: [:project_id, :environment_scope],
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }
    scope :by_environment_scope, -> (environment_scope) { where(environment_scope: environment_scope) }
  end
end
