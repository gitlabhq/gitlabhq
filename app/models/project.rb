# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime
#  updated_at             :datetime
#  creator_id             :integer
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#  issues_tracker         :string(255)      default("gitlab"), not null
#  issues_tracker_id      :string(255)
#  snippets_enabled       :boolean          default(TRUE), not null
#  last_activity_at       :datetime
#  import_url             :string(255)
#  visibility_level       :integer          default(0), not null
#  archived               :boolean          default(FALSE), not null
#  import_status          :string(255)
#

class Project < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include Gitlab::VisibilityLevel
  include Gitlab::ConfigHelper
  extend Gitlab::ConfigHelper
  extend Enumerize

  default_value_for :archived, false
  default_value_for :visibility_level, gitlab_config_features.visibility_level
  default_value_for :issues_enabled, gitlab_config_features.issues
  default_value_for :merge_requests_enabled, gitlab_config_features.merge_requests
  default_value_for :wiki_enabled, gitlab_config_features.wiki
  default_value_for :wall_enabled, false
  default_value_for :snippets_enabled, gitlab_config_features.snippets

  ActsAsTaggableOn.strict_case_match = true

  acts_as_taggable_on :labels, :issues_default_labels

  attr_accessor :new_default_branch

  # Relations
  belongs_to :creator,      foreign_key: "creator_id", class_name: "User"
  belongs_to :group, -> { where(type: Group) }, foreign_key: "namespace_id"
  belongs_to :namespace

  has_one :last_event, -> {order 'events.created_at DESC'}, class_name: 'Event', foreign_key: 'project_id'

  # Project services
  has_many :services
  has_one :gitlab_ci_service, dependent: :destroy
  has_one :campfire_service, dependent: :destroy
  has_one :emails_on_push_service, dependent: :destroy
  has_one :pivotaltracker_service, dependent: :destroy
  has_one :hipchat_service, dependent: :destroy
  has_one :flowdock_service, dependent: :destroy
  has_one :assembla_service, dependent: :destroy
  has_one :gemnasium_service, dependent: :destroy
  has_one :slack_service, dependent: :destroy
  has_one :forked_project_link, dependent: :destroy, foreign_key: "forked_to_project_id"
  has_one :forked_from_project, through: :forked_project_link
  # Merge Requests for target project should be removed with it
  has_many :merge_requests,     dependent: :destroy, foreign_key: "target_project_id"
  # Merge requests from source project should be kept when source project was removed
  has_many :fork_merge_requests, foreign_key: "source_project_id", class_name: MergeRequest
  has_many :issues, -> { order "state DESC, created_at DESC" }, dependent: :destroy
  has_many :services,           dependent: :destroy
  has_many :events,             dependent: :destroy
  has_many :milestones,         dependent: :destroy
  has_many :notes,              dependent: :destroy
  has_many :snippets,           dependent: :destroy, class_name: "ProjectSnippet"
  has_many :hooks,              dependent: :destroy, class_name: "ProjectHook"
  has_many :protected_branches, dependent: :destroy
  has_many :users_projects, dependent: :destroy
  has_many :users, through: :users_projects
  has_many :deploy_keys_projects, dependent: :destroy
  has_many :deploy_keys, through: :deploy_keys_projects

  delegate :name, to: :owner, allow_nil: true, prefix: true
  delegate :members, to: :team, prefix: true

  # Validations
  validates :creator, presence: true, on: :create
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validates :name, presence: true, length: { within: 0..255 },
            format: { with: Gitlab::Regex.project_name_regex,
                      message: Gitlab::Regex.project_regex_message }
  validates :path, presence: true, length: { within: 0..255 },
            exclusion: { in: Gitlab::Blacklist.path },
            format: { with: Gitlab::Regex.path_regex,
                      message: Gitlab::Regex.path_regex_message }
  validates :issues_enabled, :merge_requests_enabled,
            :wiki_enabled, inclusion: { in: [true, false] }
  validates :visibility_level,
    exclusion: { in: gitlab_config.restricted_visibility_levels },
    if: -> { gitlab_config.restricted_visibility_levels.any? }
  validates :issues_tracker_id, length: { maximum: 255 }, allow_blank: true
  validates :namespace, presence: true
  validates_uniqueness_of :name, scope: :namespace_id
  validates_uniqueness_of :path, scope: :namespace_id
  validates :import_url,
    format: { with: URI::regexp(%w(git http https)), message: "should be a valid url" },
    if: :import?
  validate :check_limit, on: :create

  # Scopes
  scope :without_user, ->(user)  { where("projects.id NOT IN (:ids)", ids: user.authorized_projects.map(&:id) ) }
  scope :without_team, ->(team) { team.projects.present? ? where("projects.id NOT IN (:ids)", ids: team.projects.map(&:id)) : scoped  }
  scope :not_in_group, ->(group) { where("projects.id NOT IN (:ids)", ids: group.project_ids ) }
  scope :in_team, ->(team) { where("projects.id IN (:ids)", ids: team.projects.map(&:id)) }
  scope :in_namespace, ->(namespace) { where(namespace_id: namespace.id) }
  scope :in_group_namespace, -> { joins(:group) }
  scope :sorted_by_activity, -> { reorder("projects.last_activity_at DESC") }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where("namespace_id != ?", user.namespace_id) }
  scope :public_only, -> { where(visibility_level: Project::PUBLIC) }
  scope :public_and_internal_only, -> { where(visibility_level: Project.public_and_internal_levels) }
  scope :non_archived, -> { where(archived: false) }

  enumerize :issues_tracker, in: (Gitlab.config.issues_tracker.keys).append(:gitlab), default: :gitlab

  state_machine :import_status, initial: :none do
    event :import_start do
      transition :none => :started
    end

    event :import_finish do
      transition :started => :finished
    end

    event :import_fail do
      transition :started => :failed
    end

    event :import_retry do
      transition :failed => :started
    end

    state :started
    state :finished
    state :failed

    after_transition any => :started, :do => :add_import_job
  end

  class << self
    def public_and_internal_levels
      [Project::PUBLIC, Project::INTERNAL]
    end

    def abandoned
      where('projects.last_activity_at < ?', 6.months.ago)
    end

    def publicish(user)
      visibility_levels = [Project::PUBLIC]
      visibility_levels += [Project::INTERNAL] if user
      where(visibility_level: visibility_levels)
    end

    def with_push
      includes(:events).where('events.action = ?', Event::PUSHED)
    end

    def active
      joins(:issues, :notes, :merge_requests).order("issues.created_at, notes.created_at, merge_requests.created_at DESC")
    end

    def search query
      joins(:namespace).where("projects.archived = ?", false).where("projects.name LIKE :query OR projects.path LIKE :query OR namespaces.name LIKE :query OR projects.description LIKE :query", query: "%#{query}%")
    end

    def search_by_title query
      where("projects.archived = ?", false).where("LOWER(projects.name) LIKE :query", query: "%#{query.downcase}%")
    end

    def find_with_namespace(id)
      return nil unless id.include?("/")

      id = id.split("/")
      namespace = Namespace.find_by(path: id.first)
      return nil unless namespace

      where(namespace_id: namespace.id).find_by(path: id.second)
    end

    def visibility_levels
      Gitlab::VisibilityLevel.options
    end

    def sort(method)
      case method.to_s
      when 'newest' then reorder('projects.created_at DESC')
      when 'oldest' then reorder('projects.created_at ASC')
      when 'recently_updated' then reorder('projects.updated_at DESC')
      when 'last_updated' then reorder('projects.updated_at ASC')
      when 'largest_repository' then reorder('projects.repository_size DESC')
      else reorder("namespaces.path, projects.name ASC")
      end
    end
  end

  def team
    @team ||= ProjectTeam.new(self)
  end

  def repository
    @repository ||= Repository.new(path_with_namespace)
  end

  def saved?
    id && persisted?
  end

  def add_import_job
    RepositoryImportWorker.perform_in(2.seconds, id)
  end

  def import?
    import_url.present?
  end

  def imported?
    import_finished?
  end

  def import_in_progress?
    import? && import_status == 'started'
  end

  def import_failed?
    import_status == 'failed'
  end

  def import_finished?
    import_status == 'finished'
  end

  def check_limit
    unless creator.can_create_project? or namespace.kind == 'group'
      errors[:limit_reached] << ("Your project limit is #{creator.projects_limit} projects! Please contact your administrator to increase it")
    end
  rescue
    errors[:base] << ("Can't check your ability to create project")
  end

  def to_param
    namespace.path + "/" + path
  end

  def web_url
    [gitlab_config.url, path_with_namespace].join("/")
  end

  def web_url_without_protocol
    web_url.split("://")[1]
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

  # Tags are shared by issues and merge requests
  def issues_labels
    @issues_labels ||= (issues_default_labels +
                        merge_requests.tags_on(:labels) +
                        issues.tags_on(:labels)).uniq.sort_by(&:name)
  end

  def issue_exists?(issue_id)
    if used_default_issues_tracker?
      self.issues.where(iid: issue_id).first.present?
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
    %w(gitlab_ci campfire hipchat pivotaltracker flowdock assembla emails_on_push gemnasium slack)
  end

  def gitlab_ci?
    gitlab_ci_service && gitlab_ci_service.active
  end

  def ci_services
    services.select { |service| service.category == :ci }
  end

  def ci_service
    @ci_service ||= ci_services.select(&:activated?).first
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
    NotificationService.new.project_was_moved(self)
  end

  def owner
    if group
      group
    else
      namespace.try(:owner)
    end
  end

  def team_member_by_name_or_email(name = nil, email = nil)
    user = users.where("name like ? or email like ?", name, email).first
    users_projects.where(user: user) if user
  end

  # Get Team Member record by user id
  def team_member_by_id(user_id)
    users_projects.find_by(user_id: user_id)
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

  def path_with_namespace
    if namespace
      namespace.path + '/' + path
    else
      path
    end
  end

  def execute_hooks(data, hooks_scope = :push_hooks)
    hooks.send(hooks_scope).each do |hook|
      hook.async_execute(data)
    end
  end

  def execute_services(data)
    services.each do |service|

      # Call service hook only if it is active
      begin
        service.execute(data) if service.active
      rescue => e
        logger.error(e)
      end
    end
  end

  def update_merge_requests(oldrev, newrev, ref, user)
    return true unless ref =~ /heads/
    branch_name = ref.gsub("refs/heads/", "")
    c_ids = self.repository.commits_between(oldrev, newrev).map(&:id)

    # Close merge requests
    mrs = self.merge_requests.opened.where(target_branch: branch_name).to_a
    mrs = mrs.select(&:last_commit).select { |mr| c_ids.include?(mr.last_commit.id) }
    mrs.each { |merge_request| MergeRequests::MergeService.new.execute(merge_request, user, nil) }

    # Update code for merge requests into project between project branches
    mrs = self.merge_requests.opened.by_branch(branch_name).to_a
    # Update code for merge requests between project and project fork
    mrs += self.fork_merge_requests.opened.by_branch(branch_name).to_a
    mrs.each { |merge_request| merge_request.reload_code; merge_request.mark_as_unchecked }

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
    [gitlab_config.url, "/", path_with_namespace, ".git"].join('')
  end

  # Check if current branch name is marked as protected in the system
  def protected_branch? branch_name
    protected_branches_names.include?(branch_name)
  end

  def forked?
    !(forked_project_link.nil? || forked_project_link.forked_from_project.nil?)
  end

  def personal?
    !group
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
        gitlab_shell.mv_repository("#{old_path_with_namespace}.wiki", "#{new_path_with_namespace}.wiki")
        gitlab_shell.rm_satellites(old_path_with_namespace)
        ensure_satellite_exists
        send_move_instructions
        reset_events_cache
      rescue
        # Returning false does not rollback after_* transaction but gives
        # us information about failing some of tasks
        false
      end
    else
      # if we cannot move namespace directory we should rollback
      # db changes in order to prevent out of sync between db and fs
      raise Exception.new('repository cannot be renamed')
    end
  end

  # Reset events cache related to this project
  #
  # Since we do cache @event we need to reset cache in special cases:
  # * when project was moved
  # * when project was renamed
  # Events cache stored like  events/23-20130109142513.
  # The cache key includes updated_at timestamp.
  # Thus it will automatically generate a new fragment
  # when the event is updated because the key changes.
  def reset_events_cache
    Event.where(project_id: self.id).
      order('id DESC').limit(100).
      update_all(updated_at: Time.now)
  end

  def project_member(user)
    users_projects.where(user_id: user).first
  end

  def default_branch
    @default_branch ||= repository.root_ref if repository.exists?
  end

  def reload_default_branch
    @default_branch = nil
    default_branch
  end

  def visibility_level_field
    visibility_level
  end

  def archive!
    update_attribute(:archived, true)
  end

  def unarchive!
    update_attribute(:archived, false)
  end

  def change_head(branch)
    gitlab_shell.update_repository_head(self.path_with_namespace, branch)
    reload_default_branch
  end

  def forked_from?(project)
    forked? && project == forked_from_project
  end

  def update_repository_size
    update_attribute(:repository_size, repository.size)
  end
end
