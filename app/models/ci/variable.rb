module Ci
  class Variable < ApplicationRecord
    extend Ci::Model
    include HasVariable
    include Presentable

    belongs_to :project

    validates :key, uniqueness: { scope: [:project_id, :environment_scope] }

    scope :unprotected, -> { where(protected: false) }
  end
end
