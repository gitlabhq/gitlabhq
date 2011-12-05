require "grit"

class Project < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"

  has_many :merge_requests, :dependent => :destroy
  has_many :issues, :dependent => :destroy, :order => "position"
  has_many :users_projects, :dependent => :destroy
  has_many :users, :through => :users_projects
  has_many :notes, :dependent => :destroy
  has_many :snippets, :dependent => :destroy

  acts_as_taggable

  validates :name,
            :uniqueness => true,
            :presence => true,
            :length   => { :within => 0..255 }

  validates :path,
            :uniqueness => true,
            :presence => true,
            :format => { :with => /^[a-zA-Z0-9_\-]*$/,
                         :message => "only letters, digits & '_' '-' allowed" },
            :length   => { :within => 0..255 }

  validates :description,
            :length   => { :within => 0..2000 }

  validates :code,
            :presence => true,
            :uniqueness => true,
            :format => { :with => /^[a-zA-Z0-9_\-]*$/,
                         :message => "only letters, digits & '_' '-' allowed"  },
            :length   => { :within => 3..255 }

  validates :owner,
            :presence => true

  validate :check_limit
  validate :repo_name

  after_destroy :destroy_gitosis_project
  after_save :update_gitosis_project

  attr_protected :private_flag, :owner_id

  scope :public_only, where(:private_flag => false)

  def repository
    @repository ||= Repository.new(self)
  end

  delegate :repo,
    :url_to_repo,
    :path_to_repo,
    :update_gitosis_project,
    :destroy_gitosis_project,
    :tags,
    :repo_exists?,
    :commit,
    :commits,
    :tree,
    :heads,
    :commits_since,
    :fresh_commits,
    :to => :repository, :prefix => nil

  def to_param
    code
  end

  def team_member_by_name_or_email(email = nil, name = nil)
    user = users.where("email like ? or name like ?", email, name).first
    users_projects.find_by_user_id(user.id) if user
  end

  def fresh_issues(n)
    issues.includes(:project, :author).order("created_at desc").first(n)
  end

  def fresh_notes(n)
    notes.inc_author_project.order("created_at desc").first(n)
  end

  def common_notes
    notes.where(:noteable_type => ["", nil]).inc_author_project
  end

  def build_commit_note(commit)
    notes.new(:noteable_id => commit.id, :noteable_type => "Commit")
  end

  def commit_notes(commit)
    notes.where(:noteable_id => commit.id, :noteable_type => "Commit")
  end

  def has_commits?
    !!commit
  end

  def add_access(user, *access)
    opts = { :user => user }
    access.each { |name| opts.merge!(name => true) }
    users_projects.create(opts)
  end

  def reset_access(user)
    users_projects.where(:project_id => self.id, :user_id => user.id).destroy if self.id
  end

  def writers
    @writers ||= users_projects.includes(:user).where(:write => true).map(&:user)
  end

  def gitosis_writers
    keys = Key.joins({:user => :users_projects}).where("users_projects.project_id = ? AND users_projects.write = ?", id, true)
    keys.map(&:identifier)
  end

  def readers
    @readers ||= users_projects.includes(:user).where(:read => true).map(&:user)
  end

  def admins
    @admins ||=users_projects.includes(:user).where(:admin => true).map(&:user)
  end

  def root_ref 
    "master"
  end

  def public?
    !private_flag
  end

  def private?
    private_flag
  end

  def last_activity
    updates(1).first
  rescue
    nil
  end

  def last_activity_date
    last_activity.try(:created_at)
  end

  # Get project updates from cache
  # or calculate. 
  def cached_updates(limit, expire = 2.minutes)
    activities_key = "project_#{id}_activities"
    cached_activities = Rails.cache.read(activities_key)
    if cached_activities
      activities = cached_activities
    else
      activities = updates(limit)
      Rails.cache.write(activities_key, activities, :expires_in => 60.seconds)
    end

    activities
  end

  # Get 20 events for project like
  # commits, issues or notes
  def updates(n = 3)
    [
      fresh_commits(n),
      fresh_issues(n),
      fresh_notes(n)
    ].compact.flatten.sort do |x, y|
      y.created_at <=> x.created_at
    end[0...n]
  end

  def check_limit
    unless owner.can_create_project?
      errors[:base] << ("Your own projects limit is #{owner.projects_limit}! Please contact administrator to increase it")
    end
  rescue
    errors[:base] << ("Cant check your ability to create project")
  end

  def repo_name
    if path == "gitosis-admin" && path == "gitolite-admin"
      errors.add(:path, " like 'gitosis-admin' is not allowed")
    end
  end

  def valid_repo?
    repo
  rescue
    errors.add(:path, "Invalid repository path")
    false
  end
end
# == Schema Information
#
# Table name: projects
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  path         :string(255)
#  description  :text
#  created_at   :datetime
#  updated_at   :datetime
#  private_flag :boolean         default(TRUE), not null
#  code         :string(255)
#  owner_id     :integer
#

