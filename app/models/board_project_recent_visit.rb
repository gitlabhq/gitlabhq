# frozen_string_literal: true

# Tracks which boards in a specific project a user has visited
class BoardProjectRecentVisit < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :board

  validates :user,    presence: true
  validates :project, presence: true
  validates :board,   presence: true

  scope :by_user_project, -> (user, project) { where(user: user, project: project) }

  def self.visited!(user, board)
    visit = find_or_create_by(user: user, project: board.project, board: board)
    visit.touch if visit.updated_at < Time.current
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.latest(user, project, count: nil)
    visits = by_user_project(user, project).order(updated_at: :desc)
    visits = visits.preload(:board) if count && count > 1

    visits.first(count)
  end
end
