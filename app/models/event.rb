# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  target_type :string(255)
#  target_id   :integer
#  title       :string(255)
#  data        :text
#  project_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  action      :integer
#  author_id   :integer
#

class Event < ActiveRecord::Base
  include NoteEvent
  include PushEvent

  attr_accessible :project, :action, :data, :author_id, :project_id,
                  :target_id, :target_type

  default_scope where("author_id IS NOT NULL")

  Created   = 1
  Updated   = 2
  Closed    = 3
  Reopened  = 4
  Pushed    = 5
  Commented = 6
  Merged    = 7
  Joined    = 8 # User joined project
  Left      = 9 # User left project

  delegate :name, :email, to: :author, prefix: true, allow_nil: true
  delegate :title, to: :issue, prefix: true, allow_nil: true
  delegate :title, to: :merge_request, prefix: true, allow_nil: true

  belongs_to :author, class_name: "User"
  belongs_to :project
  belongs_to :target, polymorphic: true

  # For Hash only
  serialize :data

  # Scopes
  scope :recent, order("created_at DESC")
  scope :code_push, where(action: Pushed)
  scope :in_projects, ->(project_ids) { where(project_id: project_ids).recent }

  class << self
    def determine_action(record)
      if [Issue, MergeRequest].include? record.class
        Event::Created
      elsif record.kind_of? Note
        Event::Commented
      end
    end
  end

  def proper?
    if push?
      true
    elsif membership_changed?
      true
    else
      (issue? || merge_request? || note? || milestone?) && target
    end
  end

  def project_name
    if project
      project.name
    else
      "(deleted project)"
    end
  end

  def target_title
    target.try :title
  end

  def push?
    action == self.class::Pushed && valid_push?
  end

  def merged?
    action == self.class::Merged
  end

  def closed?
    action == self.class::Closed
  end

  def reopened?
    action == self.class::Reopened
  end

  def milestone?
    target_type == "Milestone"
  end

  def note?
    target_type == "Note"
  end

  def issue?
    target_type == "Issue"
  end

  def merge_request?
    target_type == "MergeRequest"
  end

  def new_issue?
    target_type == "Issue" &&
      action == Created
  end

  def new_merge_request?
    target_type == "MergeRequest" &&
      action == Created
  end

  def changed_merge_request?
    target_type == "MergeRequest" &&
      [Closed, Reopened].include?(action)
  end

  def changed_issue?
    target_type == "Issue" &&
      [Closed, Reopened].include?(action)
  end

  def joined?
    action == Joined
  end

  def left?
    action == Left
  end

  def membership_changed?
    joined? || left?
  end

  def issue
    target if target_type == "Issue"
  end

  def merge_request
    target if target_type == "MergeRequest"
  end

  def author
    @author ||= User.find(author_id)
  end

  def action_name
    if closed?
      "closed"
    elsif merged?
      "merged"
    elsif joined?
      'joined'
    elsif left?
      'left'
    else
      "opened"
    end
  end
end
