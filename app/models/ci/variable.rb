# frozen_string_literal: true

module Ci
  class Variable < Ci::ApplicationRecord
    include Ci::HasVariable
    include Ci::Maskable
    include Ci::RawVariable
    include Ci::HidableVariable
    include Limitable
    include Presentable

    prepend HasEnvironmentScope

    belongs_to :project

    alias_attribute :secret_value, :value

    validates :description, length: { maximum: 255 }, allow_blank: true
    validates :key, uniqueness: {
      scope: [:project_id, :environment_scope],
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }
    scope :by_environment_scope, ->(environment_scope) { where(environment_scope: environment_scope) }

    self.limit_name = 'project_ci_variables'
    self.limit_scope = :project

    def audit_details
      key
    end
  end
end
