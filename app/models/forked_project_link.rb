class ForkedProjectLink < ActiveRecord::Base
  belongs_to :forked_to_project, class_name: Project
  belongs_to :forked_from_project, class_name: Project
end
