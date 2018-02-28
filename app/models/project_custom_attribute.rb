class ProjectCustomAttribute < ActiveRecord::Base
  belongs_to :project

  validates :project, :key, :value, presence: true
  validates :key, uniqueness: { scope: [:project_id] }
end
