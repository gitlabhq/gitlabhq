class Event < ActiveRecord::Base
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

  def push?
    action == self.class::Pushed
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

  def pusher
    User.find_by_id(data[:user_id])
  end
  
  def commits
    @commits ||= data[:commits].map do |commit|
      project.commit(commit[:id])
    end
  end

  delegate :id, :name, :email, :to => :pusher, :prefix => true, :allow_nil => true
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

