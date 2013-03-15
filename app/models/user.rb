# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string(255)
#  admin                  :boolean          default(FALSE), not null
#  projects_limit         :integer          default(10)
#  skype                  :string(255)      default(""), not null
#  linkedin               :string(255)      default(""), not null
#  twitter                :string(255)      default(""), not null
#  authentication_token   :string(255)
#  theme_id               :integer          default(1), not null
#  bio                    :string(255)
#  failed_attempts        :integer          default(0)
#  locked_at              :datetime
#  extern_uid             :string(255)
#  provider               :string(255)
#  username               :string(255)
#  can_create_group       :boolean          default(TRUE), not null
#  can_create_team        :boolean          default(TRUE), not null
#  state                  :string(255)
#  color_scheme_id        :integer          default(1), not null
#

class User < ActiveRecord::Base
  devise :database_authenticatable, :token_authenticatable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :registerable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :bio, :name, :username,
                  :skype, :linkedin, :twitter, :color_scheme_id, :theme_id, :force_random_password,
                  :extern_uid, :provider, as: [:default, :admin]
  attr_accessible :projects_limit, :can_create_team, :can_create_group, as: :admin

  attr_accessor :force_random_password

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace,
    dependent: :destroy,
    foreign_key: :owner_id,
    class_name: "Namespace",
    conditions: 'type IS NULL'

  # Profile
  has_many :keys, dependent: :destroy

  # Groups
  has_many :groups, class_name: "Group", foreign_key: :owner_id

  # Teams
  has_many :own_teams,
    class_name: "UserTeam",
    foreign_key: :owner_id,
    dependent: :destroy

  has_many :user_team_user_relationships, dependent: :destroy
  has_many :user_teams, through: :user_team_user_relationships
  has_many :user_team_project_relationships, through: :user_teams
  has_many :team_projects, through: :user_team_project_relationships

  # Projects
  has_many :users_projects,           dependent: :destroy
  has_many :issues,                   dependent: :destroy, foreign_key: :author_id
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id
  has_many :events,                   dependent: :destroy, foreign_key: :author_id,   class_name: "Event"
  has_many :assigned_issues,          dependent: :destroy, foreign_key: :assignee_id, class_name: "Issue"
  has_many :assigned_merge_requests,  dependent: :destroy, foreign_key: :assignee_id, class_name: "MergeRequest"
  has_many :projects, through: :users_projects

  has_many :recent_events,
    class_name: "Event",
    foreign_key: :author_id,
    order: "id DESC"

  #
  # Validations
  #
  validates :name, presence: true
  validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/ }
  validates :bio, length: { within: 0..255 }
  validates :extern_uid, allow_blank: true, uniqueness: {scope: :provider}
  validates :projects_limit, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :username, presence: true, uniqueness: true,
            format: { with: Gitlab::Regex.username_regex,
                      message: "only letters, digits & '_' '-' '.' allowed. Letter should be first" }


  validate :namespace_uniq, if: ->(user) { user.username_changed? }

  before_validation :generate_password, on: :create
  before_save :ensure_authentication_token
  alias_attribute :private_token, :authentication_token

  delegate :path, to: :namespace, allow_nil: true, prefix: true

  state_machine :state, initial: :active do
    after_transition any => :blocked do |user, transition|
      # Remove user from all projects and
      user.users_projects.find_each do |membership|
        return false unless membership.destroy
      end
    end

    event :block do
      transition active: :blocked
    end

    event :activate do
      transition blocked: :active
    end
  end

  # Scopes
  scope :admins, -> { where(admin:  true) }
  scope :blocked, -> { with_state(:blocked) }
  scope :active, -> { with_state(:active) }
  scope :alphabetically, -> { order('name ASC') }
  scope :in_team, ->(team){ where(id: team.member_ids) }
  scope :not_in_team, ->(team){ where('users.id NOT IN (:ids)', ids: team.member_ids) }
  scope :potential_team_members, ->(team) { team.members.any? ? active.not_in_team(team) : active  }

  #
  # Class methods
  #
  class << self
    def filter filter_name
      case filter_name
      when "admins"; self.admins
      when "blocked"; self.blocked
      when "wop"; self.without_projects
      else
        self.active
      end
    end

    def not_in_project(project)
      if project.users.present?
        where("id not in (:ids)", ids: project.users.map(&:id) )
      else
        scoped
      end
    end

    def without_projects
      where('id NOT IN (SELECT DISTINCT(user_id) FROM users_projects)')
    end

    def create_from_omniauth(auth, ldap = false)
      gitlab_auth.create_from_omniauth(auth, ldap)
    end

    def find_or_new_for_omniauth(auth)
      gitlab_auth.find_or_new_for_omniauth(auth)
    end

    def find_for_ldap_auth(auth, signed_in_resource = nil)
      gitlab_auth.find_for_ldap_auth(auth, signed_in_resource)
    end

    def gitlab_auth
      Gitlab::Auth.new
    end

    def search query
      where("name LIKE :query OR email LIKE :query OR username LIKE :query", query: "%#{query}%")
    end
  end

  #
  # Instance methods
  #

  def to_param
    username
  end

  def generate_password
    if self.force_random_password
      self.password = self.password_confirmation = Devise.friendly_token.first(8)
    end
  end

  def namespace_uniq
    namespace_name = self.username
    if Namespace.find_by_path(namespace_name)
      self.errors.add :username, "already exist"
    end
  end

  # Namespaces user has access to
  def namespaces
    namespaces = []

    # Add user account namespace
    namespaces << self.namespace if self.namespace

    # Add groups you can manage
    namespaces += groups.all

    namespaces
  end

  # Groups where user is an owner
  def owned_groups
    groups
  end

  # Groups user has access to
  def authorized_groups
    @authorized_groups ||= begin
                           groups = Group.where(id: self.authorized_projects.pluck(:namespace_id)).all
                           groups = groups + self.groups
                           groups.uniq
                         end
  end


  # Projects user has access to
  def authorized_projects
    project_ids = users_projects.pluck(:project_id)
    project_ids = project_ids | owned_projects.pluck(:id)
    Project.where(id: project_ids)
  end

  # Projects in user namespace
  def personal_projects
    Project.personal(self)
  end

  # Projects where user is an owner
  def owned_projects
    Project.where("(projects.namespace_id IN (:namespaces)) OR
                  (projects.namespace_id IS NULL AND projects.creator_id = :user_id)",
                  namespaces: namespaces.map(&:id), user_id: self.id)
  end

  # Team membership in authorized projects
  def tm_in_authorized_projects
    UsersProject.where(project_id:  authorized_projects.map(&:id), user_id: self.id)
  end

  def is_admin?
    admin
  end

  def require_ssh_key?
    keys.count == 0
  end

  def can_change_username?
    Gitlab.config.gitlab.username_changing_enabled
  end

  def can_create_project?
    projects_limit > owned_projects.count
  end

  def can_create_group?
    can?(:create_group, nil)
  end

  def abilities
    @abilities ||= begin
                     abilities = Six.new
                     abilities << Ability
                     abilities
                   end
  end

  def can_select_namespace?
    several_namespaces? || admin
  end

  def can? action, subject
    abilities.allowed?(self, action, subject)
  end

  def first_name
    name.split.first unless name.blank?
  end

  def cared_merge_requests
    MergeRequest.cared(self)
  end

  def projects_limit_percent
    return 100 if projects_limit.zero?
    (personal_projects.count.to_f / projects_limit) * 100
  end

  def recent_push project_id = nil
    # Get push events not earlier than 2 hours ago
    events = recent_events.code_push.where("created_at > ?", Time.now - 2.hours)
    events = events.where(project_id: project_id) if project_id

    # Take only latest one
    events = events.recent.limit(1).first
  end

  def projects_sorted_by_activity
    authorized_projects.sorted_by_activity
  end

  def several_namespaces?
    namespaces.size > 1
  end

  def namespace_id
    namespace.try :id
  end

  def authorized_teams
    @authorized_teams ||= begin
                            ids = []
                            ids << UserTeam.with_member(self).pluck('user_teams.id')
                            ids << UserTeam.created_by(self).pluck('user_teams.id')
                            ids.flatten

                            UserTeam.where(id: ids)
                          end
  end

  def owned_teams
    UserTeam.where(owner_id: self.id)
  end

  def name_with_username
    "#{name} (#{username})"
  end
end
