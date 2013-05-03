class ForkedProjectLink < ActiveRecord::Base
  attr_accessible :forked_from_project_id, :forked_to_project_id

  # Relations
  belongs_to :forked_to_project, class_name: Project
  belongs_to :forked_from_project, class_name: Project

end
