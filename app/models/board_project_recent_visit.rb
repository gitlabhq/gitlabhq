# frozen_string_literal: true

# Tracks which boards in a specific project a user has visited
class BoardProjectRecentVisit < ApplicationRecord
  include BoardRecentVisit

  belongs_to :user
  belongs_to :project
  belongs_to :board

  validates :user, presence: true
  validates :project, presence: true
  validates :board,   presence: true

  scope :by_user_parent, -> (user, project) { where(user: user, project: project) }

  def self.board_parent_relation
    :project
  end
end
