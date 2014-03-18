# == Issuable concern
#
# Contains common functionality shared between Issues and MergeRequests
#
# Used by Issue, MergeRequest
#
module Issuable
  extend ActiveSupport::Concern
  include Mentionable

  included do
    belongs_to :author, class_name: "User"
    belongs_to :assignee, class_name: "User"
    belongs_to :milestone
    has_many :notes, as: :noteable, dependent: :destroy

    validates :author, presence: true
    validates :title, presence: true, length: { within: 0..255 }

    scope :authored, ->(user) { where(author_id: user) }
    scope :assigned_to, ->(u) { where(assignee_id: u.id)}
    scope :recent, -> { order("created_at DESC") }
    scope :assigned, -> { where("assignee_id IS NOT NULL") }
    scope :unassigned, -> { where("assignee_id IS NULL") }
    scope :of_projects, ->(ids) { where(project_id: ids) }
    scope :opened, -> { with_state(:opened, :reopened) }
    scope :closed, -> { with_state(:closed) }

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

    attr_mentionable :title, :description
  end

  module ClassMethods
    def search(query)
      where("title like :query", query: "%#{query}%")
    end

    def sort(method)
      case method.to_s
      when 'newest' then reorder("#{table_name}.created_at DESC")
      when 'oldest' then reorder("#{table_name}.created_at ASC")
      when 'recently_updated' then reorder("#{table_name}.updated_at DESC")
      when 'last_updated' then reorder("#{table_name}.updated_at ASC")
      when 'milestone_due_soon' then joins(:milestone).reorder("milestones.due_date ASC")
      when 'milestone_due_later' then joins(:milestone).reorder("milestones.due_date DESC")
      else reorder("#{table_name}.created_at DESC")
      end
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

  # Return all users participating on the discussion
  def participants
    users = []
    users << author
    users << assignee if is_assigned?
    mentions = []
    mentions << self.mentioned_users
    notes.each do |note|
      users << note.author
      mentions << note.mentioned_users
    end
    users.concat(mentions.reduce([], :|)).uniq
  end

  def to_hook_data
    {
      object_kind: self.class.name.underscore,
      object_attributes: self.attributes
    }
  end
end
