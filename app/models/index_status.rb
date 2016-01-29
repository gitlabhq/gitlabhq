class IndexStatus < ActiveRecord::Base
  belongs_to :project

  validates :project_id, uniqueness: true, presence: true
end
