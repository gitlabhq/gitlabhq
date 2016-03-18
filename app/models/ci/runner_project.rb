# == Schema Information
#
# Table name: ci_runner_projects
#
#  id            :integer          not null, primary key
#  runner_id     :integer          not null
#  project_id    :integer
#  created_at    :datetime
#  updated_at    :datetime
#  gl_project_id :integer
#

module Ci
  class RunnerProject < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :runner, class_name: 'Ci::Runner'
    belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id

    validates_uniqueness_of :runner_id, scope: :gl_project_id
  end
end
