require "grit"

class Project < ActiveRecord::Base
  include Repository
  include PushObserver
  include Authority
  include Team

  #
  # Relations
  # 
  belongs_to :owner, class_name: "User"
  has_many :users,          through: :users_projects
  has_many :events,         dependent: :destroy
  has_many :merge_requests, dependent: :destroy
  has_many :issues,         dependent: :destroy, order: "closed, created_at DESC"
  has_many :milestones,     dependent: :destroy
  has_many :users_projects, dependent: :destroy
  has_many :notes,          dependent: :destroy
  has_many :snippets,       dependent: :destroy
  has_many :deploy_keys,    dependent: :destroy, foreign_key: "project_id", class_name: "Key"
  has_many :hooks,          dependent: :destroy, class_name: "ProjectHook"
  has_many :wikis,          dependent: :destroy
  has_many :protected_branches, dependent: :destroy

  attr_accessor :error_code

  # 
  # Protected attributes
  #
  attr_protected :private_flag, :owner_id

  # 
  # Scopes
  #
  scope :public_only, where(private_flag: false)
  scope :without_user, lambda { |user|  where("id not in (:ids)", ids: user.projects.map(&:id) ) }

  def self.active
    joins(:issues, :notes, :merge_requests).order("issues.created_at, notes.created_at, merge_requests.created_at DESC")
  end

  def self.search query
    where("name like :query or code like :query or path like :query", query: "%#{query}%")
  end

  def self.create_by_user(params, user)
    project = Project.new params

    Project.transaction do
      project.owner = user

      project.save!

      # Add user as project master
      project.users_projects.create!(project_access: UsersProject::MASTER, user: user)

      # when project saved no team member exist so
      # project repository should be updated after first user add
      project.update_repository
    end

    project
  rescue Gitlab::Gitolite::AccessDenied => ex
    project.error_code = :gitolite
    project
  rescue => ex
    project.error_code = :db
    project.errors.add(:base, "Can't save project. Please try again later")
    project
  end

  def git_error?
    error_code == :gitolite
  end

  def saved?
    id && valid?
  end

  #
  # Validations
  #
  validates :name,
            uniqueness: true,
            presence: true,
            length: { within: 0..255 }

  validates :path,
            uniqueness: true,
            presence: true,
            format: { with: /^[a-zA-Z][a-zA-Z0-9_\-\.]*$/,
                         message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" },
            length: { within: 0..255 }

  validates :description,
            length: { within: 0..2000 }

  validates :code,
            presence: true,
            uniqueness: true,
            format: { with: /^[a-zA-Z][a-zA-Z0-9_\-\.]*$/,
                         message: "only letters, digits & '_' '-' '.' allowed. Letter should be first"  },
            length: { within: 1..255 }

  validates :owner, presence: true
  validate :check_limit
  validate :repo_name

  def check_limit
    unless owner.can_create_project?
      errors[:base] << ("Your own projects limit is #{owner.projects_limit}! Please contact administrator to increase it")
    end
  rescue
    errors[:base] << ("Can't check your ability to create project")
  end

  def repo_name
    if path == "gitolite-admin"
      errors.add(:path, " like 'gitolite-admin' is not allowed")
    end
  end

  def self.access_options
    UsersProject.access_roles
  end

  def to_param
    code
  end

  def web_url
    [Gitlab.config.url, code].join("/")
  end

  def common_notes
    notes.where(noteable_type: ["", nil]).inc_author_project
  end

  def build_commit_note(commit)
    notes.new(noteable_id: commit.id, noteable_type: "Commit")
  end

  def commit_notes(commit)
    notes.where(noteable_id: commit.id, noteable_type: "Commit", line_code: nil)
  end

  def commit_line_notes(commit)
    notes.where(noteable_id: commit.id, noteable_type: "Commit").where("line_code is not null")
  end

  def public?
    !private_flag
  end

  def private?
    private_flag
  end

  def last_activity
    events.last || nil
  end

  def last_activity_date
    if events.last
      events.last.created_at
    else
      updated_at
    end
  end

  def project_id
    self.id
  end
end

# == Schema Information
#
# Table name: projects
#
#  id                     :integer(4)      not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  private_flag           :boolean(1)      default(TRUE), not null
#  code                   :string(255)
#  owner_id               :integer(4)
#  default_branch         :string(255)     default("master"), not null
#  issues_enabled         :boolean(1)      default(TRUE), not null
#  wall_enabled           :boolean(1)      default(TRUE), not null
#  merge_requests_enabled :boolean(1)      default(TRUE), not null
#  wiki_enabled           :boolean(1)      default(TRUE), not null
#

