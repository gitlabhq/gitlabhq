module Ci
  class ProjectVariable < ActiveRecord::Base
    extend Ci::Model
    include HasVariable

    self.table_name = 'ci_variables'

    belongs_to :project

    validates :key, uniqueness: { scope: :project_id }

    scope :unprotected, -> { where(protected: false) }
  end
end
