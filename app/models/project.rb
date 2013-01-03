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
#  creator_id             :integer
#  default_branch         :string(255)
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#

require "grit"

class Project < ActiveRecord::Base
  include Gitolited

  class TransferError < StandardError; end

  attr_accessible :name, :path, :description, :default_branch, :issues_enabled,
                  :wall_enabled, :merge_requests_enabled, :wiki_enabled, as: [:default, :admin]

  attr_accessible :namespace_id, :creator_id, as: :admin

  attr_accessor :error_code

  # Relations
  belongs_to :group, foreign_key: "namespace_id", conditions: "type = 'Group'"
  belongs_to :namespace

  belongs_to :creator,
    class_name: "User",
    foreign_key: "creator_id"

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
  validates :creator, presence: true
  validates :description, length: { within: 0..2000 }
  validates :name, presence: true, length: { within: 0..255 },
            format: { with: Gitlab::Regex.project_name_regex,
                      message: "only letters, digits, spaces & '_' '-' '.' allowed. Letter should be first" }
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
  scope :without_user, ->(user)  { where("id NOT IN (:ids)", ids: user.authorized_projects.map(&:id) ) }
  scope :not_in_group, ->(group) { where("id NOT IN (:ids)", ids: group.project_ids ) }
  scope :in_namespace, ->(namespace) { where(namespace_id: namespace.id) }
  scope :sorted_by_activity, ->() { order("(SELECT max(events.created_at) FROM events WHERE events.project_id = projects.id) DESC") }
  scope :personal, ->(user) { where(namespace_id: user.namespace_id) }
  scope :joined, ->(user) { where("namespace_id != ?", user.namespace_id) }

  class << self
    def authorized_for user
      raise "DERECATED"
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

        project.creator = user

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
    unless creator.can_create_project?
      errors[:base] << ("Your own projects limit is #{creator.projects_limit}! Please contact administrator to increase it")
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

  # Add user to project
  # with passed access role
  def add_user_to_team(user, access_role)
    add_user_id_to_team(user.id, access_role)
  end

  # Add multiple users to project
  # with same access role
  def add_users_to_team(users, access_role)
    add_users_ids_to_team(users.map(&:id), access_role)
  end

  # Add user to project
  # with passed access role by user id
  def add_user_id_to_team(user_id, access_role)
    users_projects.create(
      user_id: user_id,
      project_access: access_role
    )
  end

  # Add multiple users to project
  # with same access role by user ids
  def add_users_ids_to_team(users_ids, access_role)
    UsersProject.bulk_import(self, users_ids, access_role)
  end

  # Update multiple project users
  # to same access role by user ids
  def update_users_ids_to_role(users_ids, access_role)
    UsersProject.bulk_update(self, users_ids, access_role)
  end

  # Delete multiple users from project by user ids
  def delete_users_ids_from_team(users_ids)
    UsersProject.bulk_delete(self, users_ids)
  end

  # Remove all users from project team
  def truncate_team
    UsersProject.truncate_team(self)
  end

  # Compatible with all access rights
  # Should be rewrited for new access rights
  def add_access(user, *access)
    access = if access.include?(:admin)
               { project_access: UsersProject::MASTER }
             elsif access.include?(:write)
               { project_access: UsersProject::DEVELOPER }
             else
               { project_access: UsersProject::REPORTER }
             end
    opts = { user: user }
    opts.merge!(access)
    users_projects.create(opts)
  end

  def reset_access(user)
    users_projects.where(project_id: self.id, user_id: user.id).destroy if self.id
  end

  def repository_readers
    repository_members[UsersProject::REPORTER]
  end

  def repository_writers
    repository_members[UsersProject::DEVELOPER]
  end

  def repository_masters
    repository_members[UsersProject::MASTER]
  end

  def repository_members
    keys = Hash.new {|h,k| h[k] = [] }
    UsersProject.select("keys.identifier, project_access").
        joins(user: :keys).where(project_id: id).
        each {|row| keys[row.project_access] << [row.identifier] }

    keys[UsersProject::REPORTER] += deploy_keys.pluck(:identifier)
    keys
  end

  def allow_read_for?(user)
    !users_projects.where(user_id: user.id).empty?
  end

  def guest_access_for?(user)
    !users_projects.where(user_id: user.id).empty?
  end

  def report_access_for?(user)
    !users_projects.where(user_id: user.id, project_access: [UsersProject::REPORTER, UsersProject::DEVELOPER, UsersProject::MASTER]).empty?
  end

  def dev_access_for?(user)
    !users_projects.where(user_id: user.id, project_access: [UsersProject::DEVELOPER, UsersProject::MASTER]).empty?
  end

  def master_access_for?(user)
    !users_projects.where(user_id: user.id, project_access: [UsersProject::MASTER]).empty?
  end

  def transfer(new_namespace)
    Project.transaction do
      old_namespace = namespace
      self.namespace = new_namespace

      old_dir = old_namespace.try(:path) || ''
      new_dir = new_namespace.try(:path) || ''

      old_repo = if old_dir.present?
                   File.join(old_dir, self.path)
                 else
                   self.path
                 end

      if Project.where(path: self.path, namespace_id: new_namespace.try(:id)).present?
        raise TransferError.new("Project with same path in target namespace already exists")
      end

      Gitlab::ProjectMover.new(self, old_dir, new_dir).execute

      gitolite.move_repository(old_repo, self)

      save!
    end
  rescue Gitlab::ProjectMover::ProjectMoveError => ex
    raise Project::TransferError.new(ex.message)
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

  # This method will be called after each post receive and only if the provided
  # user is present in GitLab.
  #
  # All callbacks for post receive should be placed here.
  def trigger_post_receive(oldrev, newrev, ref, user)
    data = post_receive_data(oldrev, newrev, ref, user)

    # Create push event
    self.observe_push(data)

    if push_to_branch? ref, oldrev
      # Close merged MR
      self.update_merge_requests(oldrev, newrev, ref, user)

      # Execute web hooks
      self.execute_hooks(data.dup)

      # Execute project services
      self.execute_services(data.dup)
    end

    # Create satellite
    self.satellite.create unless self.satellite.exists?

    # Discover the default branch, but only if it hasn't already been set to
    # something else
    if default_branch.nil?
      update_attributes(default_branch: discover_default_branch)
    end
  end

  def push_to_branch? ref, oldrev
    ref_parts = ref.split('/')

    # Return if this is not a push to a branch (e.g. new commits)
    !(ref_parts[1] !~ /heads/ || oldrev == "00000000000000000000000000000000")
  end

  def observe_push(data)
    Event.create(
      project: self,
      action: Event::Pushed,
      data: data,
      author_id: data[:user_id]
    )
  end

  def execute_hooks(data)
    hooks.each { |hook| hook.execute(data) }
  end

  def execute_services(data)
    services.each do |service|

      # Call service hook only if it is active
      service.execute(data) if service.active
    end
  end

  # Produce a hash of post-receive data
  #
  # data = {
  #   before: String,
  #   after: String,
  #   ref: String,
  #   user_id: String,
  #   user_name: String,
  #   repository: {
  #     name: String,
  #     url: String,
  #     description: String,
  #     homepage: String,
  #   },
  #   commits: Array,
  #   total_commits_count: Fixnum
  # }
  #
  def post_receive_data(oldrev, newrev, ref, user)

    push_commits = commits_between(oldrev, newrev)

    # Total commits count
    push_commits_count = push_commits.size

    # Get latest 20 commits ASC
    push_commits_limited = push_commits.last(20)

    # Hash to be passed as post_receive_data
    data = {
      before: oldrev,
      after: newrev,
      ref: ref,
      user_id: user.id,
      user_name: user.name,
      repository: {
        name: name,
        url: url_to_repo,
        description: description,
        homepage: web_url,
      },
      commits: [],
      total_commits_count: push_commits_count
    }

    # For perfomance purposes maximum 20 latest commits
    # will be passed as post receive hook data.
    #
    push_commits_limited.each do |commit|
      data[:commits] << {
        id: commit.id,
        message: commit.safe_message,
        timestamp: commit.date.xmlschema,
        url: "#{Gitlab.config.gitlab.url}/#{path_with_namespace}/commit/#{commit.id}",
        author: {
          name: commit.author_name,
          email: commit.author_email
        }
      }
    end

    data
  end

  def update_merge_requests(oldrev, newrev, ref, user)
    return true unless ref =~ /heads/
    branch_name = ref.gsub("refs/heads/", "")
    c_ids = self.commits_between(oldrev, newrev).map(&:id)

    # Update code for merge requests
    mrs = self.merge_requests.opened.find_all_by_branch(branch_name).all
    mrs.each { |merge_request| merge_request.reload_code; merge_request.mark_as_unchecked }

    # Close merge requests
    mrs = self.merge_requests.opened.where(target_branch: branch_name).all
    mrs = mrs.select(&:last_commit).select { |mr| c_ids.include?(mr.last_commit.id) }
    mrs.each { |merge_request| merge_request.merge!(user.id) }

    true
  end

  def valid_repo?
    repo
  rescue
    errors.add(:path, "Invalid repository path")
    false
  end

  def empty_repo?
    !repo_exists? || !has_commits?
  end

  def commit(commit_id = nil)
    Commit.find_or_first(repo, commit_id, root_ref)
  end

  def fresh_commits(n = 10)
    Commit.fresh_commits(repo, n)
  end

  def commits_with_refs(n = 20)
    Commit.commits_with_refs(repo, n)
  end

  def commits_since(date)
    Commit.commits_since(repo, date)
  end

  def commits(ref, path = nil, limit = nil, offset = nil)
    Commit.commits(repo, ref, path, limit, offset)
  end

  def last_commit_for(ref, path = nil)
    commits(ref, path, 1).first
  end

  def commits_between(from, to)
    Commit.commits_between(repo, from, to)
  end

  def satellite
    @satellite ||= Gitlab::Satellite::Satellite.new(self)
  end

  def has_post_receive_file?
    !!hook_file
  end

  def valid_post_receive_file?
    valid_hook_file == hook_file
  end

  def valid_hook_file
    @valid_hook_file ||= File.read(Rails.root.join('lib', 'hooks', 'post-receive'))
  end

  def hook_file
    @hook_file ||= begin
                     hook_path = File.join(path_to_repo, 'hooks', 'post-receive')
                     File.read(hook_path) if File.exists?(hook_path)
                   end
  end

  # Returns an Array of branch names
  def branch_names
    repo.branches.collect(&:name).sort
  end

  # Returns an Array of Branches
  def branches
    repo.branches.sort_by(&:name)
  end

  # Returns an Array of tag names
  def tag_names
    repo.tags.collect(&:name).sort.reverse
  end

  # Returns an Array of Tags
  def tags
    repo.tags.sort_by(&:name).reverse
  end

  # Returns an Array of branch and tag names
  def ref_names
    [branch_names + tag_names].flatten
  end

  def repo
    @repo ||= Grit::Repo.new(path_to_repo)
  end

  def url_to_repo
    gitolite.url_to_repo(path_with_namespace)
  end

  def path_to_repo
    File.join(Gitlab.config.gitolite.repos_path, "#{path_with_namespace}.git")
  end

  def namespace_dir
    namespace.try(:path) || ''
  end

  def update_repository
    gitolite.update_repository(self)
  end

  def destroy_repository
    gitolite.remove_repository(self)
  end

  def repo_exists?
    @repo_exists ||= (repo && !repo.branches.empty?)
  rescue
    @repo_exists = false
  end

  def heads
    @heads ||= repo.heads
  end

  def tree(fcommit, path = nil)
    fcommit = commit if fcommit == :head
    tree = fcommit.tree
    path ? (tree / path) : tree
  end

  def open_branches
    if protected_branches.empty?
      self.repo.heads
    else
      pnames = protected_branches.map(&:name)
      self.repo.heads.reject { |h| pnames.include?(h.name) }
    end.sort_by(&:name)
  end

  # Discovers the default branch based on the repository's available branches
  #
  # - If no branches are present, returns nil
  # - If one branch is present, returns its name
  # - If two or more branches are present, returns the one that has a name
  #   matching root_ref (default_branch or 'master' if default_branch is nil)
  def discover_default_branch
    if branch_names.length == 0
      nil
    elsif branch_names.length == 1
      branch_names.first
    else
      branch_names.select { |v| v == root_ref }.first
    end
  end

  def has_commits?
    !!commit
  rescue Grit::NoSuchPathError
    false
  end

  def root_ref
    default_branch || "master"
  end

  def root_ref?(branch)
    root_ref == branch
  end

  # Archive Project to .tar.gz
  #
  # Already packed repo archives stored at
  # app_root/tmp/repositories/project_name/project_name-commit-id.tag.gz
  #
  def archive_repo(ref)
    ref = ref || self.root_ref
    commit = self.commit(ref)
    return nil unless commit

    # Build file path
    file_name = self.path + "-" + commit.id.to_s + ".tar.gz"
    storage_path = Rails.root.join("tmp", "repositories", self.path_with_namespace)
    file_path = File.join(storage_path, file_name)

    # Put files into a directory before archiving
    prefix = self.path + "/"

    # Create file if not exists
    unless File.exists?(file_path)
      FileUtils.mkdir_p storage_path
      file = self.repo.archive_to_file(ref, prefix,  file_path)
    end

    file_path
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    http_url = [Gitlab.config.gitlab.url, "/", path_with_namespace, ".git"].join('')
  end

  # Check if current branch name is marked as protected in the system
  def protected_branch? branch_name
    protected_branches.map(&:name).include?(branch_name)
  end
end
