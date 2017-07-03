class ForkedProjectLink < ActiveRecord::Base
  belongs_to :forked_to_project, -> { where.not(pending_delete: true) }, class_name: 'Project'
  belongs_to :forked_from_project, -> { where.not(pending_delete: true) }, class_name: 'Project'
end
