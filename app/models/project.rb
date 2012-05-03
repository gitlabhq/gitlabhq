require "grit"

class Project < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"

  does "project/validations"
  does "project/repository"
  does "project/permissions"
  does "project/hooks"

  has_many :users,          :through => :users_projects
  has_many :events,         :dependent => :destroy
  has_many :merge_requests, :dependent => :destroy
  has_many :issues,         :dependent => :destroy, :order => "position"
  has_many :milestones,     :dependent => :destroy
  has_many :users_projects, :dependent => :destroy
  has_many :notes,          :dependent => :destroy
  has_many :snippets,       :dependent => :destroy
  has_many :deploy_keys,    :dependent => :destroy, :foreign_key => "project_id", :class_name => "Key"
  has_many :web_hooks,      :dependent => :destroy
  has_many :wikis,          :dependent => :destroy
  has_many :protected_branches, :dependent => :destroy

  attr_protected :private_flag, :owner_id

  scope :public_only, where(:private_flag => false)
  scope :without_user, lambda { |user|  where("id not in (:ids)", :ids => user.projects.map(&:id) ) }

  def self.active
    joins(:issues, :notes, :merge_requests).order("issues.created_at, notes.created_at, merge_requests.created_at DESC")
  end

  def self.access_options
    UsersProject.access_roles
  end

  def self.search query
    where("name like :query or code like :query or path like :query", :query => "%#{query}%")
  end

  def to_param
    code
  end

  def web_url
    [GIT_HOST['host'], code].join("/")
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

  def write_hooks
    %w(post-receive).each do |hook|
      write_hook(hook, File.read(File.join(Rails.root, 'lib', "#{hook}-hook")))
    end
  end

  def write_hook(name, content)
    hook_file = File.join(path_to_repo, 'hooks', name)
    cur_content = File.read(hook_file)

    unless cur_content == content 
      FileUtils.copy(hook_file, hook_file + '.' + Time.now.to_i.to_s)
      File.open(hook_file, 'w') do |f|
        f.write(content)
      end  
      cur_perm=sprintf("%o", File.stat(hook_file).mode)
      unless cur_perm == "100775"
        File.chmod(0775, hook_file)
      end
      return 0
    end  

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

