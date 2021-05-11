# frozen_string_literal: true

# Tracks which boards in a specific group a user has visited
class BoardGroupRecentVisit < ApplicationRecord
  include BoardRecentVisit

  belongs_to :user
  belongs_to :group
  belongs_to :board

  validates :user, presence: true
  validates :group, presence: true
  validates :board, presence: true

  scope :by_user_parent, -> (user, group) { where(user: user, group: group) }

  def self.board_parent_relation
    :group
  end
end
