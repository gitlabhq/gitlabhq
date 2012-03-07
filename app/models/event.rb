class Event < ActiveRecord::Base
  default_scope where("author_id IS NOT NULL")

  Created   = 1
  Updated   = 2
  Closed    = 3
  Reopened  = 4
  Pushed    = 5
  Commented = 6

  belongs_to :project
  belongs_to :target, :polymorphic => true

  serialize :data

  scope :recent, order("created_at DESC")

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
    push? || new_issue? || new_merge_request? || 
      changed_merge_request? || changed_issue?
  end

  def push?
    action == self.class::Pushed
  end

  def closed?
    action == self.class::Closed
  end

  def reopened?
    action == self.class::Reopened
  end

  def new_tag? 
    data[:ref]["refs/tags"]
  end

  def new_branch?
    data[:before] =~ /^00000/
  end

  def commit_from
    data[:before]
  end

  def commit_to
    data[:after]
  end

  def branch_name
    @branch_name ||= data[:ref].gsub("refs/heads/", "")
  end

  def tag_name
    @tag_name ||= data[:ref].gsub("refs/tags/", "")
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
  
  def commits
    @commits ||= data[:commits].map do |commit|
      project.commit(commit[:id])
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

