# frozen_string_literal: true

module Ci
  class Variable < ApplicationRecord
    extend Gitlab::Ci::Model
    include HasVariable
    include Presentable
    include Maskable
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
