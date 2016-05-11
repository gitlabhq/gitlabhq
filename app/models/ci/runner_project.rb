module Ci
  class RunnerProject < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :runner, class_name: 'Ci::Runner'
    belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id

    validates_uniqueness_of :runner_id, scope: :gl_project_id
  end
end
