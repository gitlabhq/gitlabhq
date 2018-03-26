module Ci
  class Variable < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include HasVariable
    include Presentable
    prepend HasEnvironmentScope

    belongs_to :project

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      scope: [:project_id, :environment_scope],
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }
  end
end
