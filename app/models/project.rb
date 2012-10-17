require "grit"

class Project < ActiveRecord::Base
  include Repository
  include PushObserver
  include Authority
  include Team

  attr_accessible :name, :path, :description, :code, :default_branch, :issues_enabled,
                  :wall_enabled, :merge_requests_enabled, :wiki_enabled
  attr_accessor :error_code

  # Relations
  belongs_to :group
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
  has_one :last_event, class_name: 'Event', order: 'events.created_at DESC', foreign_key: 'project_id'

  delegate :name, to: :owner, allow_nil: true, prefix: true

  # Validations
  validates :owner, presence: true
  validates :description, length: { within: 0..2000 }
  validates :name, uniqueness: true, presence: true, length: { within: 0..255 }
  validates :path, uniqueness: true, presence: true, length: { within: 0..255 },
            format: { with: /\A[a-zA-Z][a-zA-Z0-9_\-\.]*\z/,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }
  validates :code, presence: true, uniqueness: true, length: { within: 1..255 },
            format: { with: /\A[a-zA-Z][a-zA-Z0-9_\-\.]*\z/,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }
  validates :issues_enabled, :wall_enabled, :merge_requests_enabled,
            :wiki_enabled, inclusion: { in: [true, false] }
  validate :check_limit, :repo_name

  # Scopes
  scope :public_only, where(private_flag: false)
  scope :without_user, ->(user)  { where("id NOT IN (:ids)", ids: user.projects.map(&:id) ) }
  scope :not_in_group, ->(group) { where("id NOT IN (:ids)", ids: group.project_ids ) }

  class << self
    def active
      joins(:issues, :notes, :merge_requests).order("issues.created_at, notes.created_at, merge_requests.created_at DESC")
    end

    def search query
      where("name LIKE :query OR code LIKE :query OR path LIKE :query", query: "%#{query}%")
    end

    def create_by_user(params, user)
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

    def access_options
      UsersProject.access_roles
    end
  end

  def git_error?
    error_code == :gitolite
  end

  def saved?
    id && valid?
  end

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
    notes.where(noteable_id: commit.id, noteable_type: "Commit").where("line_code IS NOT NULL")
  end

  def public?
    !private_flag
  end

  def private?
    private_flag
  end

  def last_activity
    last_event
  end

  def last_activity_date
    last_event.try(:created_at) || updated_at
  end

  def wiki_notes
    Note.where(noteable_id: wikis.pluck(:id), noteable_type: 'Wiki', project_id: self.id)
  end

  def project_id
    self.id
  end

  def issues_labels
    issues.tag_counts_on(:labels)
  end
end

# == Schema Information
#
# Table name: projects
#
#  id                     :integer         not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  private_flag           :boolean         default(TRUE), not null
#  code                   :string(255)
#  owner_id               :integer
#  default_branch         :string(255)
#  issues_enabled         :boolean         default(TRUE), not null
#  wall_enabled           :boolean         default(TRUE), not null
#  merge_requests_enabled :boolean         default(TRUE), not null
#  wiki_enabled           :boolean         default(TRUE), not null
#  group_id               :integer
#

