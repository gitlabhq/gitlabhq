require "grit"

class Project < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"

  has_many :issues, :dependent => :destroy, :order => "position"
  has_many :users_projects, :dependent => :destroy
  has_many :users, :through => :users_projects
  has_many :notes, :dependent => :destroy
  has_many :snippets, :dependent => :destroy

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
  
  after_destroy :destroy_gitosis_project
  after_save :update_gitosis_project

  attr_protected :private_flag, :owner_id

  scope :public_only, where(:private_flag => false)

  def to_param
    code
  end

  def common_notes
    notes.where(:noteable_type => ["", nil])
  end

  def update_gitosis_project
    Gitosis.new.configure do |c|
      c.update_project(path, gitosis_writers)
    end
  end
  
  def destroy_gitosis_project
    Gitosis.new.configure do |c|
      c.destroy_project(self)
    end
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

  def public?
    !private_flag
  end

  def private?
    private_flag
  end

  def url_to_repo
    "#{GITOSIS["git_user"]}@#{GITOSIS["host"]}:#{path}.git"
  end
  
  def path_to_repo
    GITOSIS["base_path"] + path + ".git"
  end

  def repo 
    @repo ||= Grit::Repo.new(path_to_repo)
  end

  def tags
    repo.tags.map(&:name).sort.reverse
  end

  def repo_exists?
    repo rescue false
  end

  def commit(commit_id = nil)
    if commit_id
      repo.commits(commit_id).first
    else 
      repo.commits.first
    end
  end

  def tree(fcommit, path = nil)
    fcommit = commit if fcommit == :head
    tree = fcommit.tree
    path ? (tree / path) : tree
  end

  def check_limit
    unless owner.can_create_project?
      errors[:base] << ("Your own projects limit is #{owner.projects_limit}! Please contact administrator to increase it")
    end
  rescue 
    errors[:base] << ("Cant check your ability to create project")
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

