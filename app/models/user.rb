# == Schema Information
#
# Table name: users
#
#  id                       :integer          not null, primary key
#  email                    :string(255)      default(""), not null
#  encrypted_password       :string(255)      default(""), not null
#  reset_password_token     :string(255)
#  reset_password_sent_at   :datetime
#  remember_created_at      :datetime
#  sign_in_count            :integer          default(0)
#  current_sign_in_at       :datetime
#  last_sign_in_at          :datetime
#  current_sign_in_ip       :string(255)
#  last_sign_in_ip          :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  name                     :string(255)
#  admin                    :boolean          default(FALSE), not null
#  projects_limit           :integer          default(10)
#  skype                    :string(255)      default(""), not null
#  linkedin                 :string(255)      default(""), not null
#  twitter                  :string(255)      default(""), not null
#  authentication_token     :string(255)
#  theme_id                 :integer          default(1), not null
#  bio                      :string(255)
#  failed_attempts          :integer          default(0)
#  locked_at                :datetime
#  extern_uid               :string(255)
#  provider                 :string(255)
#  username                 :string(255)
#  can_create_group         :boolean          default(TRUE), not null
#  can_create_team          :boolean          default(TRUE), not null
#  state                    :string(255)
#  color_scheme_id          :integer          default(1), not null
#  notification_level       :integer          default(1), not null
#  password_expires_at      :datetime
#  created_by_id            :integer
#  last_credential_check_at :datetime
#  avatar                   :string(255)
#  confirmation_token       :string(255)
#  confirmed_at             :datetime
#  confirmation_sent_at     :datetime
#  unconfirmed_email        :string(255)
#  hide_no_ssh_key          :boolean          default(FALSE)
#  website_url              :string(255)      default(""), not null
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class User < ActiveRecord::Base
  include Gitlab::ConfigHelper
  extend Gitlab::ConfigHelper
  include TokenAuthenticatable

  default_value_for :admin, false
  default_value_for :can_create_group, gitlab_config.default_can_create_group
  default_value_for :can_create_team, false
  default_value_for :hide_no_ssh_key, false
  default_value_for :projects_limit, gitlab_config.default_projects_limit
  default_value_for :theme_id, gitlab_config.default_theme

  devise :database_authenticatable, :lockable, :async,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :confirmable, :registerable

  attr_accessor :force_random_password

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace, -> { where type: nil }, dependent: :destroy, foreign_key: :owner_id, class_name: "Namespace"

  # Profile
  has_many :keys, dependent: :destroy
  has_many :emails, dependent: :destroy

  # Groups
  has_many :users_groups, dependent: :destroy
  has_many :groups, through: :users_groups
  has_many :owned_groups, -> { where users_groups: { group_access: UsersGroup::OWNER } }, through: :users_groups, source: :group
  has_many :masters_groups, -> { where users_groups: { group_access: UsersGroup::MASTER } }, through: :users_groups, source: :group

  # Projects
  has_many :groups_projects,          through: :groups, source: :projects
  has_many :personal_projects,        through: :namespace, source: :projects
  has_many :projects,                 through: :users_projects
  has_many :created_projects,         foreign_key: :creator_id, class_name: 'Project'

  has_many :snippets,                 dependent: :destroy, foreign_key: :author_id, class_name: "Snippet"
  has_many :users_projects,           dependent: :destroy
  has_many :issues,                   dependent: :destroy, foreign_key: :author_id
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id
  has_many :events,                   dependent: :destroy, foreign_key: :author_id,   class_name: "Event"
  has_many :recent_events, -> { order "id DESC" }, foreign_key: :author_id,   class_name: "Event"
  has_many :assigned_issues,          dependent: :destroy, foreign_key: :assignee_id, class_name: "Issue"
  has_many :assigned_merge_requests,  dependent: :destroy, foreign_key: :assignee_id, class_name: "MergeRequest"


  #
  # Validations
  #
  validates :name, presence: true
  validates :email, presence: true, email: {strict_mode: true}, uniqueness: true
  validates :bio, length: { maximum: 255 }, allow_blank: true
  validates :extern_uid, allow_blank: true, uniqueness: {scope: :provider}
  validates :projects_limit, presence: true, numericality: {greater_than_or_equal_to: 0}
  validates :username, presence: true, uniqueness: { case_sensitive: false },
            exclusion: { in: Gitlab::Blacklist.path },
            format: { with: Gitlab::Regex.username_regex,
                      message: Gitlab::Regex.username_regex_message }

  validates :notification_level, inclusion: { in: Notification.notification_levels }, presence: true
  validate :namespace_uniq, if: ->(user) { user.username_changed? }
  validate :avatar_type, if: ->(user) { user.avatar_changed? }
  validate :unique_email, if: ->(user) { user.email_changed? }
  validates :avatar, file_size: { maximum: 100.kilobytes.to_i }

  before_validation :generate_password, on: :create
  before_validation :sanitize_attrs

  before_save :ensure_authentication_token
  after_save :ensure_namespace_correct
  after_create :post_create_hook
  after_destroy :post_destroy_hook


  alias_attribute :private_token, :authentication_token

  delegate :path, to: :namespace, allow_nil: true, prefix: true

  state_machine :state, initial: :active do
    after_transition any => :blocked do |user, transition|
      # Remove user from all projects and
      user.users_projects.find_each do |membership|
        # skip owned resources
        next if membership.project.owner == user

        return false unless membership.destroy
      end

      # Remove user from all groups
      user.users_groups.find_each do |membership|
        # skip owned resources
        next if membership.group.last_owner?(user)

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

  mount_uploader :avatar, AttachmentUploader

  # Scopes
  scope :admins, -> { where(admin:  true) }
  scope :blocked, -> { with_state(:blocked) }
  scope :active, -> { with_state(:active) }
  scope :alphabetically, -> { order('name ASC') }
  scope :in_team, ->(team){ where(id: team.member_ids) }
  scope :not_in_team, ->(team){ where('users.id NOT IN (:ids)', ids: team.member_ids) }
  scope :not_in_project, ->(project) { project.users.present? ? where("id not in (:ids)", ids: project.users.map(&:id) ) : all }
  scope :without_projects, -> { where('id NOT IN (SELECT DISTINCT(user_id) FROM users_projects)') }
  scope :ldap, -> { where(provider:  'ldap') }

  scope :potential_team_members, ->(team) { team.members.any? ? active.not_in_team(team) : active  }

  #
  # Class methods
  #
  class << self
    # Devise method overridden to allow sign in with email or username
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).where(["lower(username) = :value OR lower(email) = :value", { value: login.downcase }]).first
      else
        where(conditions).first
      end
    end

    def find_for_commit(email, name)
      # Prefer email match over name match
      User.where(email: email).first ||
        User.joins(:emails).where(emails: { email: email }).first ||
        User.where(name: name).first
    end

    def filter filter_name
      case filter_name
      when "admins"; self.admins
      when "blocked"; self.blocked
      when "wop"; self.without_projects
      else
        self.active
      end
    end

    def search query
      where("lower(name) LIKE :query OR lower(email) LIKE :query OR lower(username) LIKE :query", query: "%#{query.downcase}%")
    end

    def by_username_or_id(name_or_id)
      where('users.username = ? OR users.id = ?', name_or_id.to_s, name_or_id.to_i).first
    end

    def build_user(attrs = {})
      User.new(attrs)
    end
  end

  #
  # Instance methods
  #

  def to_param
    username
  end

  def notification
    @notification ||= Notification.new(self)
  end

  def generate_password
    if self.force_random_password
      self.password = self.password_confirmation = Devise.friendly_token.first(8)
    end
  end

  def namespace_uniq
    namespace_name = self.username
    if Namespace.find_by(path: namespace_name)
      self.errors.add :username, "already exists"
    end
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, "only images allowed"
    end
  end

  def unique_email
    self.errors.add(:email, 'has already been taken') if Email.exists?(email: self.email)
  end

  # Groups user has access to
  def authorized_groups
    @authorized_groups ||= begin
                             group_ids = (groups.pluck(:id) + authorized_projects.pluck(:namespace_id))
                             Group.where(id: group_ids).order('namespaces.name ASC')
                           end
  end


  # Projects user has access to
  def authorized_projects
    @authorized_projects ||= begin
                               project_ids = personal_projects.pluck(:id)
                               project_ids += groups_projects.pluck(:id)
                               project_ids += projects.pluck(:id).uniq
                               Project.where(id: project_ids).joins(:namespace).order('namespaces.name ASC')
                             end
  end

  def owned_projects
    @owned_projects ||= begin
                          Project.where(namespace_id: owned_groups.pluck(:id).push(namespace.id)).joins(:namespace)
                        end
  end

  # Team membership in authorized projects
  def tm_in_authorized_projects
    UsersProject.where(project_id: authorized_projects.map(&:id), user_id: self.id)
  end

  def is_admin?
    admin
  end

  def require_ssh_key?
    keys.count == 0
  end

  def can_change_username?
    gitlab_config.username_changing_enabled
  end

  def can_create_project?
    projects_limit_left > 0
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

  def projects_limit_left
    projects_limit - personal_projects.count
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
    owned_groups.any? || masters_groups.any?
  end

  def namespace_id
    namespace.try :id
  end

  def name_with_username
    "#{name} (#{username})"
  end

  def tm_of(project)
    project.team_member_by_id(self.id)
  end

  def already_forked? project
    !!fork_of(project)
  end

  def fork_of project
    links = ForkedProjectLink.where(forked_from_project_id: project, forked_to_project_id: personal_projects)

    if links.any?
      links.first.forked_to_project
    else
      nil
    end
  end

  def ldap_user?
    extern_uid && provider == 'ldap'
  end

  def accessible_deploy_keys
    DeployKey.in_projects(self.authorized_projects.pluck(:id)).uniq
  end

  def created_by
    User.find_by(id: created_by_id) if created_by_id
  end

  def sanitize_attrs
    %w(name username skype linkedin twitter bio).each do |attr|
      value = self.send(attr)
      self.send("#{attr}=", Sanitize.clean(value)) if value.present?
    end
  end

  def requires_ldap_check?
    if ldap_user?
      !last_credential_check_at || (last_credential_check_at + 1.hour) < Time.now
    else
      false
    end
  end

  def solo_owned_groups
    @solo_owned_groups ||= owned_groups.select do |group|
      group.owners == [self]
    end
  end

  def with_defaults
    User.defaults.each do |k, v|
      self.send("#{k}=", v)
    end

    self
  end

  def can_leave_project?(project)
    project.namespace != namespace &&
      project.project_member(self)
  end

  # Reset project events cache related to this user
  #
  # Since we do cache @event we need to reset cache in special cases:
  # * when the user changes their avatar
  # Events cache stored like  events/23-20130109142513.
  # The cache key includes updated_at timestamp.
  # Thus it will automatically generate a new fragment
  # when the event is updated because the key changes.
  def reset_events_cache
    Event.where(author_id: self.id).
      order('id DESC').limit(1000).
      update_all(updated_at: Time.now)
  end

  def full_website_url
    return "http://#{website_url}" if website_url !~ /^https?:\/\//

    website_url
  end

  def short_website_url
    website_url.gsub(/https?:\/\//, '')
  end

  def all_ssh_keys
    keys.map(&:key)
  end

  def temp_oauth_email?
    email =~ /\Atemp-email-for-oauth/
  end

  def generate_tmp_oauth_email
    self.email = "temp-email-for-oauth-#{username}@gitlab.localhost"
  end

  def public_profile?
    authorized_projects.public_only.any?
  end

  def avatar_url(size = nil)
    if avatar.present?
      [gitlab_config.url, avatar.url].join("/")
    else
      GravatarService.new.execute(email, size)
    end
  end

  def ensure_namespace_correct
    # Ensure user has namespace
    self.create_namespace!(path: self.username, name: self.username) unless self.namespace

    if self.username_changed?
      self.namespace.update_attributes(path: self.username, name: self.username)
    end
  end

  def post_create_hook
    log_info("User \"#{self.name}\" (#{self.email}) was created")
    notification_service.new_user(self)
    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_destroy_hook
    log_info("User \"#{self.name}\" (#{self.email})  was removed")
    system_hook_service.execute_hooks_for(self, :destroy)
  end

  def notification_service
    NotificationService.new
  end

  def log_info message
    Gitlab::AppLogger.info message
  end

  def system_hook_service
    SystemHooksService.new
  end
end
