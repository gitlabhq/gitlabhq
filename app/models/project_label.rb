class ProjectLabel < Label
  belongs_to :project

  validates :project, presence: true
end
