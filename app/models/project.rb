require "grit"

class Project < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"

  has_many :users,          :through => :users_projects
  has_many :events,         :dependent => :destroy
  has_many :merge_requests, :dependent => :destroy
  has_many :issues,         :dependent => :destroy, :order => "position"
  has_many :users_projects, :dependent => :destroy
  has_many :notes,          :dependent => :destroy
  has_many :snippets,       :dependent => :destroy
  has_many :deploy_keys,    :dependent => :destroy, :foreign_key => "project_id", :class_name => "Key"
  has_many :web_hooks,      :dependent => :destroy
  has_many :wikis,          :dependent => :destroy
  has_many :protected_branches, :dependent => :destroy

  validates :name,
            :uniqueness => true,
            :presence => true,
            :length   => { :within => 0..255 }

  validates :path,
            :uniqueness => true,
            :presence => true,
            :format => { :with => /^[a-zA-Z0-9_\-\.]*$/,
                         :message => "only letters, digits & '_' '-' '.' allowed" },
            :length   => { :within => 0..255 }

  validates :description,
            :length   => { :within => 0..2000 }

  validates :code,
            :presence => true,
            :uniqueness => true,
            :format => { :with => /^[a-zA-Z0-9_\-\.]*$/,
                         :message => "only letters, digits & '_' '-' '.' allowed"  },
            :length   => { :within => 3..255 }

  validates :owner, :presence => true
  validate :check_limit
  validate :repo_name

  attr_protected :private_flag, :owner_id

  scope :public_only, where(:private_flag => false)
  scope :without_user, lambda { |user|  where("id not in (:ids)", :ids => user.projects.map(&:id) ) }

  def self.active
    joins(:issues, :notes, :merge_requests).order("issues.created_at, notes.created_at, merge_requests.created_at DESC")
  end

  def self.access_options
    UsersProject.access_roles
  end

  def to_param
    code
  end

  def web_url
    [GIT_HOST['host'], code].join("/")
  end

  def observe_push(oldrev, newrev, ref, author_key_id)
    data = web_hook_data(oldrev, newrev, ref, author_key_id)

    Event.create(
      :project => self,
      :action => Event::Pushed,
      :data => data,
      :author_id => data[:user_id]
    )
  end

  def execute_web_hooks(oldrev, newrev, ref, author_key_id)
    ref_parts = ref.split('/')

    # Return if this is not a push to a branch (e.g. new commits)
    return if ref_parts[1] !~ /heads/ || oldrev == "00000000000000000000000000000000"

    data = web_hook_data(oldrev, newrev, ref, author_key_id)

    web_hooks.each { |web_hook| web_hook.execute(data) }
  end

  def web_hook_data(oldrev, newrev, ref, author_key_id)
    key = Key.find_by_identifier(author_key_id)
    data = {
      before: oldrev,
      after: newrev,
      ref: ref,
      user_id: key.user.id,
      user_name: key.user_name,
      repository: {
        name: name,
        url: web_url,
        description: description,
        homepage: web_url,
        private: private?
      },
      commits: []
    }

    commits_between(oldrev, newrev).each do |commit|
      data[:commits] << {
        id: commit.id,
        message: commit.safe_message,
        timestamp: commit.date.xmlschema,
        url: "http://#{GIT_HOST['host']}/#{code}/commits/#{commit.id}",
        author: {
          name: commit.author_name,
          email: commit.author_email
        }
      }
    end

    data
  end

  def open_branches
    if protected_branches.empty?
      self.repo.heads
    else
      pnames = protected_branches.map(&:name)
      self.repo.heads.reject { |h| pnames.include?(h.name) }
    end.sort_by(&:name)
  end

  def team_member_by_name_or_email(email = nil, name = nil)
    user = users.where("email like ? or name like ?", email, name).first
    users_projects.find_by_user_id(user.id) if user
  end

  def team_member_by_id(user_id)
    users_projects.find_by_user_id(user_id)
  end

  def common_notes
    notes.where(:noteable_type => ["", nil]).inc_author_project
  end

  def build_commit_note(commit)
    notes.new(:noteable_id => commit.id, :noteable_type => "Commit")
  end

  def commit_notes(commit)
    notes.where(:noteable_id => commit.id, :noteable_type => "Commit", :line_code => nil)
  end

  def commit_line_notes(commit)
    notes.where(:noteable_id => commit.id, :noteable_type => "Commit").where("line_code is not null")
  end

  def has_commits?
    !!commit
  end

  # Compatible with all access rights
  # Should be rewrited for new access rights
  def add_access(user, *access)
    access = if access.include?(:admin) 
               { :project_access => UsersProject::MASTER } 
             elsif access.include?(:write)
               { :project_access => UsersProject::DEVELOPER } 
             else
               { :project_access => UsersProject::REPORTER } 
             end
    opts = { :user => user }
    opts.merge!(access)
    users_projects.create(opts)
  end

  def reset_access(user)
    users_projects.where(:project_id => self.id, :user_id => user.id).destroy if self.id
  end

  def repository_readers
    keys = Key.joins({:user => :users_projects}).
      where("users_projects.project_id = ? AND users_projects.project_access = ?", id, UsersProject::REPORTER)
    keys.map(&:identifier) + deploy_keys.map(&:identifier)
  end

  def repository_writers
    keys = Key.joins({:user => :users_projects}).
      where("users_projects.project_id = ? AND users_projects.project_access = ?", id, UsersProject::DEVELOPER)
    keys.map(&:identifier)
  end

  def repository_masters
    keys = Key.joins({:user => :users_projects}).
      where("users_projects.project_id = ? AND users_projects.project_access = ?", id, UsersProject::MASTER)
    keys.map(&:identifier)
  end

  def allow_read_for?(user)
    !users_projects.where(:user_id => user.id).empty?
  end

  def guest_access_for?(user)
    !users_projects.where(:user_id => user.id).empty?
  end

  def report_access_for?(user)
    !users_projects.where(:user_id => user.id, :project_access => [UsersProject::REPORTER, UsersProject::DEVELOPER, UsersProject::MASTER]).empty?
  end

  def dev_access_for?(user)
    !users_projects.where(:user_id => user.id, :project_access => [UsersProject::DEVELOPER, UsersProject::MASTER]).empty?
  end

  def master_access_for?(user)
    !users_projects.where(:user_id => user.id, :project_access => [UsersProject::MASTER]).empty? || owner_id == user.id
  end

  def root_ref 
    default_branch || "master"
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

  def check_limit
    unless owner.can_create_project?
      errors[:base] << ("Your own projects limit is #{owner.projects_limit}! Please contact administrator to increase it")
    end
  rescue
    errors[:base] << ("Cant check your ability to create project")
  end

  def repo_name
    if path == "gitolite-admin"
      errors.add(:path, " like 'gitolite-admin' is not allowed")
    end
  end

  def valid_repo?
    repo
  rescue
    errors.add(:path, "Invalid repository path")
    false
  end

  def commit(commit_id = nil)
    Commit.find_or_first(repo, commit_id)
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

  def commits_between(from, to)
    Commit.commits_between(repo, from, to)
  end

  def project_id
    self.id
  end

  def write_hooks
    %w(post-receive).each do |hook|
      write_hook(hook, File.read(File.join(Rails.root, 'lib', "#{hook}-hook")))
    end
  end

  def write_hook(name, content)
    hook_file = File.join(path_to_repo, 'hooks', name)

    File.open(hook_file, 'w') do |f|
      f.write(content)
    end

    File.chmod(0775, hook_file)
  end

  def repo
    @repo ||= Grit::Repo.new(path_to_repo)
  end

  def url_to_repo
    Gitlabhq::GitHost.url_to_repo(path)
  end

  def path_to_repo
    File.join(GIT_HOST["base_path"], "#{path}.git")
  end

  def update_repository
    Gitlabhq::GitHost.system.update_project(path, self)

    write_hooks if File.exists?(path_to_repo)
  end

  def destroy_repository
    Gitlabhq::GitHost.system.destroy_project(self)
  end

  def repo_exists?
    @repo_exists ||= (repo && !repo.branches.empty?)
  rescue 
    @repo_exists = false
  end

  def tags
    repo.tags.map(&:name).sort.reverse
  end

  def heads
    @heads ||= repo.heads
  end

  def tree(fcommit, path = nil)
    fcommit = commit if fcommit == :head
    tree = fcommit.tree
    path ? (tree / path) : tree
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
#  created_at             :datetime
#  updated_at             :datetime
#  private_flag           :boolean         default(TRUE), not null
#  code                   :string(255)
#  owner_id               :integer
#  default_branch         :string(255)     default("master"), not null
#  issues_enabled         :boolean         default(TRUE), not null
#  wall_enabled           :boolean         default(TRUE), not null
#  merge_requests_enabled :boolean         default(TRUE), not null
#  wiki_enabled           :boolean         default(TRUE), not null
#

