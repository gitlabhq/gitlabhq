# frozen_string_literal: true

# Tracks which boards in a specific group a user has visited
class BoardGroupRecentVisit < ApplicationRecord
  belongs_to :user
  belongs_to :group
  belongs_to :board

  validates :user,  presence: true
  validates :group, presence: true
  validates :board, presence: true

  scope :by_user_group, -> (user, group) { where(user: user, group: group) }

  def self.visited!(user, board)
    visit = find_or_create_by(user: user, group: board.group, board: board)
    visit.touch if visit.updated_at < Time.current
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.latest(user, group, count: nil)
    visits = by_user_group(user, group).order(updated_at: :desc)
    visits = visits.preload(:board) if count && count > 1

    visits.first(count)
  end
end
