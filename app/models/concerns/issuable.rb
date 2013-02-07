# == Issuable concern
#
# Contains common functionality shared between Issues and MergeRequests
#
# Used by Issue, MergeRequest
#
module Issuable
  extend ActiveSupport::Concern

  included do
    belongs_to :project
    belongs_to :author, class_name: "User"
    belongs_to :assignee, class_name: "User"
    belongs_to :milestone
    has_many :notes, as: :noteable, dependent: :destroy

    validates :project, presence: true
    validates :author, presence: true
    validates :title, presence: true, length: { within: 0..255 }
    validates :closed, inclusion: { in: [true, false] }

    scope :opened, where(closed: false)
    scope :closed, where(closed: true)
    scope :of_group, ->(group) { where(project_id: group.project_ids) }
    scope :of_user_team, ->(team) { where(project_id: team.project_ids, assignee_id: team.member_ids) }
    scope :assigned, ->(u) { where(assignee_id: u.id)}
    scope :recent, order("created_at DESC")

    delegate :name,
             :email,
             to: :author,
             prefix: true

    delegate :name,
             :email,
             to: :assignee,
             allow_nil: true,
             prefix: true

    attr_accessor :author_id_of_changes
  end

  module ClassMethods
    def search(query)
      where("title like :query", query: "%#{query}%")
    end
  end

  def today?
    Date.today == created_at.to_date
  end

  def new?
    today? && created_at == updated_at
  end

  def is_assigned?
    !!assignee_id
  end

  def is_being_reassigned?
    assignee_id_changed?
  end

  def is_being_closed?
    closed_changed? && closed
  end

  def is_being_reopened?
    closed_changed? && !closed
  end

  #
  # Votes
  #

  # Return the number of -1 comments (downvotes)
  def downvotes
    notes.select(&:downvote?).size
  end

  def downvotes_in_percent
    if votes_count.zero?
      0
    else
      100.0 - upvotes_in_percent
    end
  end

  # Return the number of +1 comments (upvotes)
  def upvotes
    notes.select(&:upvote?).size
  end

  def upvotes_in_percent
    if votes_count.zero?
      0
    else
      100.0 / votes_count * upvotes
    end
  end

  # Return the total number of votes
  def votes_count
    upvotes + downvotes
  end
end
