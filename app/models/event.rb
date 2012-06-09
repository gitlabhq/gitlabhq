class Event < ActiveRecord::Base
  include PushEvent

  default_scope where("author_id IS NOT NULL")

  Created   = 1
  Updated   = 2
  Closed    = 3
  Reopened  = 4
  Pushed    = 5
  Commented = 6
  Merged    = 7

  belongs_to :project
  belongs_to :target, :polymorphic => true

  # For Hash only
  serialize :data

  scope :recent, order("created_at DESC")
  scope :code_push, where(:action => Pushed)

  def self.determine_action(record)
    if [Issue, MergeRequest].include? record.class
      Event::Created
    elsif record.kind_of? Note
      Event::Commented
    end
  end

  # Next events currently enabled for system
  #  - push 
  #  - new issue
  #  - merge request
  def allowed?
    push? || issue? || merge_request?
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
    else 
      "opened"
    end
  end

  delegate :name, :email, :to => :author, :prefix => true, :allow_nil => true
  delegate :title, :to => :issue, :prefix => true, :allow_nil => true
  delegate :title, :to => :merge_request, :prefix => true, :allow_nil => true
end
# == Schema Information
#
# Table name: events
#
#  id          :integer         not null, primary key
#  target_type :string(255)
#  target_id   :integer
#  title       :string(255)
#  data        :text
#  project_id  :integer
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#  action      :integer
#

