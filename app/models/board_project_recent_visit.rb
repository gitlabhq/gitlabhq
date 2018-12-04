# frozen_string_literal: true

# Tracks which boards in a specific project a user has visited
class BoardProjectRecentVisit < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :board

  validates :user,    presence: true
  validates :project, presence: true
  validates :board,   presence: true

  scope :by_user_project, -> (user, project) { where(user: user, project: project).order(:updated_at) }

  def self.visited!(user, board)
    visit = find_or_create_by(user: user, project: board.project, board: board)
    visit.touch if visit.updated_at < Time.now
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.latest(user, project)
    by_user_project(user, project).last
  end
end
