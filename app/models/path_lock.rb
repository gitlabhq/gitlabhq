class PathLock < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  validates :project, presence: true
  validates :user, presence: true
  validates :path, presence: true, uniqueness: { scope: [:user, :project] }
end
