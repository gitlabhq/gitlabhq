# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  private_flag           :boolean          default(TRUE), not null
#  owner_id               :integer
#  default_branch         :string(255)
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#

require "grit"

class Project < ActiveRecord::Base
  include Repository
  include PushObserver
  include Authority
  include Team
  include NamespacedProject

  class TransferError < StandardError; end

  attr_accessible :name, :path, :description, :default_branch, :issues_enabled,
                  :wall_enabled, :merge_requests_enabled, :wiki_enabled, as: [:default, :admin]

  attr_accessible :namespace_id, :owner_id, as: :admin

  attr_accessor :error_code

  # Relations
  belongs_to :group, foreign_key: "namespace_id", conditions: "type = 'Group'"
  belongs_to :namespace

  # TODO: replace owner with creator.
  # With namespaces a project owner will be a namespace owner
  # so this field makes sense only for global projects
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
  has_one :gitlab_ci_service, dependent: :destroy

  delegate :name, to: :owner, allow_nil: true, prefix: true

  # Validations
  validates :owner, presence: true
  validates :description, length: { within: 0..2000 }
  validates :name, presence: true, length: { within: 0..255 }
  validates :path, presence: true, length: { within: 0..255 },
            format: { with: Gitlab::Regex.path_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }
  validates :issues_enabled, :wall_enabled, :merge_requests_enabled,
            :wiki_enabled, inclusion: { in: [true, false] }

  validates_uniqueness_of :name, scope: :namespace_id
  validates_uniqueness_of :path, scope: :namespace_id

  validate :check_limit, :repo_name

  # Scopes
  scope :public_only, where(private_flag: false)
  scope :without_user, ->(user)  { where("id NOT IN (:ids)", ids: user.projects.map(&:id) ) }
  scope :not_in_group, ->(group) { where("id NOT IN (:ids)", ids: group.project_ids ) }
  scope :sorted_by_activity, ->() { order("(SELECT max(events.created_at) FROM events WHERE events.project_id = projects.id) DESC") }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where("namespace_id != ?", user.namespace_id) }

  class << self
    def authorized_for user
      projects = includes(:users_projects, :namespace)
      projects = projects.where("users_projects.user_id = :user_id or projects.owner_id = :user_id or namespaces.owner_id = :user_id", user_id: user.id)
    end

    def active
      joins(:issues, :notes, :merge_requests).order("issues.created_at, notes.created_at, merge_requests.created_at DESC")
    end

    def search query
      where("projects.name LIKE :query OR projects.path LIKE :query", query: "%#{query}%")
    end

    def find_with_namespace(id)
      if id.include?("/")
        id = id.split("/")
        namespace_id = Namespace.find_by_path(id.first).id
        where(namespace_id: namespace_id).find_by_path(id.last)
      else
        where(path: id, namespace_id: nil).last
      end
    end

    def create_by_user(params, user)
      namespace_id = params.delete(:namespace_id)

      project = Project.new params

      Project.transaction do

        # Parametrize path for project
        #
        # Ex.
        #  'GitLab HQ'.parameterize => "gitlab-hq"
        #
        project.path = project.name.dup.parameterize

        project.owner = user

        # Apply namespace if user has access to it
        # else fallback to user namespace
        if namespace_id != Namespace.global_id
          project.namespace_id = user.namespace_id

          if namespace_id
            group = Group.find_by_id(namespace_id)
            if user.can? :manage_group, group
              project.namespace_id = namespace_id
            end
          end
        end

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
    denied_paths = %w(gitolite-admin admin dashboard groups help profile projects search)

    if denied_paths.include?(path)
      errors.add(:path, "like #{path} is not allowed")
    end
  end

  def to_param
    if namespace
      namespace.path + "/" + path
    else
      path
    end
  end

  def web_url
    [Gitlab.config.gitlab.url, path_with_namespace].join("/")
  end

  def common_notes
    notes.where(noteable_type: ["", nil]).inc_author_project
  end

  def build_commit_note(commit)
    notes.new(commit_id: commit.id, noteable_type: "Commit")
  end

  def commit_notes(commit)
    notes.where(commit_id: commit.id, noteable_type: "Commit", line_code: nil)
  end

  def commit_line_notes(commit)
    notes.where(commit_id: commit.id, noteable_type: "Commit").where("line_code IS NOT NULL")
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

  def project_id
    self.id
  end

  def issues_labels
    issues.tag_counts_on(:labels)
  end

  def services
    [gitlab_ci_service].compact
  end

  def gitlab_ci?
    gitlab_ci_service && gitlab_ci_service.active
  end

  # For compatibility with old code
  def code
    path
  end

  def items_for entity
    case entity
    when 'issue' then
      issues
    when 'merge_request' then
      merge_requests
    end
  end

  def send_move_instructions
    self.users_projects.each do |member|
      Notify.project_was_moved_email(member.id).deliver
    end
  end
end
