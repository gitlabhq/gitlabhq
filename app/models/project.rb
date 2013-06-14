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
#  creator_id             :integer
#  default_branch         :string(255)
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#  public                 :boolean          default(FALSE), not null
#  issues_tracker         :string(255)      default("gitlab"), not null
#  issues_tracker_id      :string(255)
#  snippets_enabled       :boolean          default(TRUE), not null
#  last_activity_at       :datetime
#

require "grit"

class Project < ActiveRecord::Base
  include Gitlab::ShellAdapter
  extend Enumerize

  attr_accessible :name, :path, :description, :default_branch, :issues_tracker, :label_list,
    :issues_enabled, :wall_enabled, :merge_requests_enabled, :snippets_enabled, :issues_tracker_id,
    :wiki_enabled, :public, :import_url, :last_activity_at, as: [:default, :admin]

  attr_accessible :namespace_id, :creator_id, as: :admin

  acts_as_taggable_on :labels, :issues_default_labels

  attr_accessor :import_url

  # Relations
  belongs_to :creator,      foreign_key: "creator_id", class_name: "User"
  belongs_to :group,        foreign_key: "namespace_id", conditions: "type = 'Group'"
  belongs_to :namespace

  has_one :last_event, class_name: 'Event', order: 'events.created_at DESC', foreign_key: 'project_id'
  has_one :gitlab_ci_service, dependent: :destroy
  has_one :campfire_service, dependent: :destroy
  has_one :hipchat_service, dependent: :destroy
  has_one :forked_project_link, dependent: :destroy, foreign_key: "forked_to_project_id"
  has_one :forked_from_project, through: :forked_project_link

  has_many :services,           dependent: :destroy
  has_many :events,             dependent: :destroy
  has_many :merge_requests,     dependent: :destroy
  has_many :issues,             dependent: :destroy, order: "state DESC, created_at DESC"
  has_many :milestones,         dependent: :destroy
  has_many :users_projects,     dependent: :destroy
  has_many :notes,              dependent: :destroy
  has_many :snippets,           dependent: :destroy, class_name: "ProjectSnippet"
  has_many :hooks,              dependent: :destroy, class_name: "ProjectHook"
  has_many :protected_branches, dependent: :destroy
  has_many :user_team_project_relationships, dependent: :destroy

  has_many :users,          through: :users_projects
  has_many :user_teams,     through: :user_team_project_relationships
  has_many :user_team_user_relationships, through: :user_teams
  has_many :user_teams_members, through: :user_team_user_relationships

  has_many :deploy_keys_projects, dependent: :destroy
  has_many :deploy_keys, through: :deploy_keys_projects

  delegate :name, to: :owner, allow_nil: true, prefix: true

  # Validations
  validates :creator, presence: true
  validates :description, length: { within: 0..2000 }
  validates :name, presence: true, length: { within: 0..255 },
            format: { with: Gitlab::Regex.project_name_regex,
                      message: "only letters, digits, spaces & '_' '-' '.' allowed. Letter should be first" }
  validates :path, presence: true, length: { within: 0..255 },
            exclusion: { in: Gitlab::Blacklist.path },
            format: { with: Gitlab::Regex.path_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }
  validates :issues_enabled, :wall_enabled, :merge_requests_enabled,
            :wiki_enabled, inclusion: { in: [true, false] }
  validates :issues_tracker_id, length: { within: 0..255 }

  validates_uniqueness_of :name, scope: :namespace_id
  validates_uniqueness_of :path, scope: :namespace_id

  validates :import_url,
    format: { with: URI::regexp(%w(http https)), message: "should be a valid url" },
    if: :import?

  validate :check_limit

  # Scopes
  scope :without_user, ->(user)  { where("projects.id NOT IN (:ids)", ids: user.authorized_projects.map(&:id) ) }
  scope :without_team, ->(team) { team.projects.present? ? where("projects.id NOT IN (:ids)", ids: team.projects.map(&:id)) : scoped  }
  scope :not_in_group, ->(group) { where("projects.id NOT IN (:ids)", ids: group.project_ids ) }
  scope :in_team, ->(team) { where("projects.id IN (:ids)", ids: team.projects.map(&:id)) }
  scope :in_namespace, ->(namespace) { where(namespace_id: namespace.id) }
  scope :in_group_namespace, -> { joins(:group) }
  scope :sorted_by_activity, -> { order("projects.last_activity_at DESC") }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where("namespace_id != ?", user.namespace_id) }
  scope :public_only, -> { where(public: true) }

  enumerize :issues_tracker, in: (Gitlab.config.issues_tracker.keys).append(:gitlab), default: :gitlab

  class << self
    def abandoned
      where('projects.last_activity_at < ?', 6.months.ago)
    end

    def with_push
      includes(:events).where('events.action = ?', Event::PUSHED)
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
        namespace = Namespace.find_by_path(id.first)
        return nil unless namespace

        where(namespace_id: namespace.id).find_by_path(id.second)
      else
        where(path: id, namespace_id: nil).last
      end
    end

    def access_options
      UsersProject.access_roles
    end
  end

  def team
    @team ||= ProjectTeam.new(self)
  end

  def repository
    @repository ||= Repository.new(path_with_namespace, default_branch)
  end

  def saved?
    id && persisted?
  end

  def import?
    import_url.present?
  end

  def check_limit
    unless creator.can_create_project?
      errors[:limit_reached] << ("Your own projects limit is #{creator.projects_limit}! Please contact administrator to increase it")
    end
  rescue
    errors[:base] << ("Can't check your ability to create project")
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

  def build_commit_note(commit)
    notes.new(commit_id: commit.id, noteable_type: "Commit")
  end

  def last_activity
    last_event
  end

  def last_activity_date
    last_activity_at || updated_at
  end

  def project_id
    self.id
  end

  def issues_labels
    @issues_labels ||= (issues_default_labels + issues.tags_on(:labels)).uniq.sort_by(&:name)
  end

  def issue_exists?(issue_id)
    if used_default_issues_tracker?
      self.issues.where(id: issue_id).first.present?
    else
      true
    end
  end

  def used_default_issues_tracker?
    self.issues_tracker == Project.issues_tracker.default_value
  end

  def can_have_issues_tracker_id?
    self.issues_enabled && !self.used_default_issues_tracker?
  end

  def build_missing_services
    available_services_names.each do |service_name|
      service = services.find { |service| service.to_param == service_name }

      # If service is available but missing in db
      # we should create an instance. Ex `create_gitlab_ci_service`
      service = self.send :"create_#{service_name}_service" if service.nil?
    end
  end

  def available_services_names
    %w(gitlab_ci campfire hipchat)
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
      Notify.delay.project_was_moved_email(member.id)
    end
  end

  def owner
    if namespace
      namespace_owner
    else
      creator
    end
  end

  def team_member_by_name_or_email(name = nil, email = nil)
    user = users.where("name like ? or email like ?", name, email).first
    users_projects.where(user: user) if user
  end

  # Get Team Member record by user id
  def team_member_by_id(user_id)
    users_projects.find_by_user_id(user_id)
  end

  def name_with_namespace
    @name_with_namespace ||= begin
                               if namespace
                                 namespace.human_name + " / " + name
                               else
                                 name
                               end
                             end
  end

  def namespace_owner
    namespace.try(:owner)
  end

  def path_with_namespace
    if namespace
      namespace.path + '/' + path
    else
      path
    end
  end

  def transfer(new_namespace)
    ProjectTransferService.new.transfer(self, new_namespace)
  end

  def execute_hooks(data)
    hooks.each { |hook| hook.async_execute(data) }
  end

  def execute_services(data)
    services.each do |service|

      # Call service hook only if it is active
      service.execute(data) if service.active
    end
  end

  def discover_default_branch
    # Discover the default branch, but only if it hasn't already been set to
    # something else
    if repository && default_branch.nil?
      update_attributes(default_branch: self.repository.discover_default_branch)
    end
  end

  def update_merge_requests(oldrev, newrev, ref, user)
    return true unless ref =~ /heads/
    branch_name = ref.gsub("refs/heads/", "")
    c_ids = self.repository.commits_between(oldrev, newrev).map(&:id)

    # Update code for merge requests
    mrs = self.merge_requests.opened.by_branch(branch_name).all
    mrs.each { |merge_request| merge_request.reload_code; merge_request.mark_as_unchecked }

    # Close merge requests
    mrs = self.merge_requests.opened.where(target_branch: branch_name).all
    mrs = mrs.select(&:last_commit).select { |mr| c_ids.include?(mr.last_commit.id) }
    mrs.each { |merge_request| merge_request.merge!(user.id) }

    true
  end

  def valid_repo?
    repository.exists?
  rescue
    errors.add(:path, "Invalid repository path")
    false
  end

  def empty_repo?
    !repository.exists? || repository.empty?
  end

  def ensure_satellite_exists
    self.satellite.create unless self.satellite.exists?
  end

  def satellite
    @satellite ||= Gitlab::Satellite::Satellite.new(self)
  end

  def repo
    repository.raw
  end

  def url_to_repo
    gitlab_shell.url_to_repo(path_with_namespace)
  end

  def namespace_dir
    namespace.try(:path) || ''
  end

  def repo_exists?
    @repo_exists ||= repository.exists?
  rescue
    @repo_exists = false
  end

  def open_branches
    all_branches = repository.branches

    if protected_branches.present?
      all_branches.reject! do |branch|
        protected_branches_names.include?(branch.name)
      end
    end

    all_branches
  end

  def protected_branches_names
    @protected_branches_names ||= protected_branches.map(&:name)
  end

  def root_ref?(branch)
    repository.root_ref == branch
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    http_url = [Gitlab.config.gitlab.url, "/", path_with_namespace, ".git"].join('')
  end

  def project_access_human(member)
    project_user_relation = self.users_projects.find_by_user_id(member.id)
    self.class.access_options.key(project_user_relation.project_access)
  end

  # Check if current branch name is marked as protected in the system
  def protected_branch? branch_name
    protected_branches_names.include?(branch_name)
  end

  def forked?
    !(forked_project_link.nil? || forked_project_link.forked_from_project.nil?)
  end

  def imported?
    imported
  end

  def rename_repo
    old_path_with_namespace = File.join(namespace_dir, path_was)
    new_path_with_namespace = File.join(namespace_dir, path)

    if gitlab_shell.mv_repository(old_path_with_namespace, new_path_with_namespace)
      # If repository moved successfully we need to remove old satellite
      # and send update instructions to users.
      # However we cannot allow rollback since we moved repository
      # So we basically we mute exceptions in next actions
      begin
        gitlab_shell.rm_satellites(old_path_with_namespace)
        send_move_instructions
      rescue
        # Returning false does not rolback after_* transaction but gives
        # us information about failing some of tasks
        false
      end
    else
      # if we cannot move namespace directory we should rollback
      # db changes in order to prevent out of sync between db and fs
      raise Exception.new('repository cannot be renamed')
    end
  end
end
