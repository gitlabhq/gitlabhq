module Ci
  class ProjectVariable < Ci::Variable
    self.table_name = 'ci_variables'

    belongs_to :project

    validates :key, uniqueness: { scope: :project_id }
  end
end
