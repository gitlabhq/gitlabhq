# == Schema Information
#
# Table name: ci_runner_projects
#
#  id         :integer          not null, primary key
#  runner_id  :integer          not null
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#

module Ci
  class RunnerProject < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :runner, class_name: 'Ci::Runner'
    belongs_to :project, class_name: 'Ci::Project'

    validates_uniqueness_of :runner_id, scope: :project_id
  end
end
