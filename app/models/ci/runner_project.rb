module Ci
  class RunnerProject < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :runner
    belongs_to :project, foreign_key: :gl_project_id

    validates :runner_id, uniqueness: { scope: :gl_project_id }
  end
end
