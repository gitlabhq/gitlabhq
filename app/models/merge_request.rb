require File.join(Rails.root, "app/models/commit")

class MergeRequest < ActiveRecord::Base
  belongs_to :project
  belongs_to :author, :class_name => "User"
  belongs_to :assignee, :class_name => "User"
  has_many :notes, :as => :noteable, :dependent => :destroy

  serialize :st_commits
  serialize :st_diffs

  attr_protected :author, :author_id, :project, :project_id
  attr_accessor :author_id_of_changes

  validates_presence_of :project_id
  validates_presence_of :assignee_id
  validates_presence_of :author_id
  validates_presence_of :source_branch
  validates_presence_of :target_branch
  validate :validate_branches

  delegate :name,
           :email,
           :to => :author,
           :prefix => true

  delegate :name,
           :email,
           :to => :assignee,
           :prefix => true

  validates :title,
            :presence => true,
            :length   => { :within => 0..255 }

  scope :opened, where(:closed => false)
  scope :closed, where(:closed => true)
  scope :assigned, lambda { |u| where(:assignee_id => u.id)}

  def self.search query
    where("title like :query", :query => "%#{query}%")
  end

  def validate_branches
    if target_branch == source_branch
      errors.add :base, "You can not use same branch for source and target branches"
    end
  end

  def new?
    today? && created_at == updated_at
  end

  def diffs
    st_diffs || []
  end

  def reloaded_diffs
    if open? && unmerged_diffs.any?
      self.st_diffs = unmerged_diffs
      save
    end
    diffs
  end

  def unmerged_diffs
    commits = project.repo.commits_between(target_branch, source_branch).map {|c| Commit.new(c)}
    diffs = project.repo.diff(commits.first.prev_commit.id, commits.last.id) rescue []
  end

  def last_commit
    commits.first
  end

  def merge_event
    self.project.events.where(:target_id => self.id, :target_type => "MergeRequest", :action => Event::Merged).last
  end

  # Return the number of +1 comments (upvotes)
  def upvotes
    notes.select(&:upvote?).size
  end

  def commits
    st_commits || []
  end

  def probably_merged?
    unmerged_commits.empty? && 
      commits.any? && open?
  end

  def open?
    !closed
  end

  def mark_as_merged!
    self.merged = true
    self.closed = true
    save
  end

  def reloaded_commits 
    if open? && unmerged_commits.any? 
      self.st_commits = unmerged_commits
      save
    end
    commits
  end

  def unmerged_commits
    self.project.repo.
      commits_between(self.target_branch, self.source_branch).
      map {|c| Commit.new(c)}.
      sort_by(&:created_at).
      reverse
  end
end
# == Schema Information
#
# Table name: merge_requests
#
#  id            :integer         not null, primary key
#  target_branch :string(255)     not null
#  source_branch :string(255)     not null
#  project_id    :integer         not null
#  author_id     :integer
#  assignee_id   :integer
#  title         :string(255)
#  closed        :boolean         default(FALSE), not null
#  created_at    :datetime
#  updated_at    :datetime
#

