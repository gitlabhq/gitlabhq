# == Schema Information
#
# Table name: users
#
#  id                          :integer          not null, primary key
#  email                       :string(255)      default(""), not null
#  encrypted_password          :string(255)      default(""), not null
#  reset_password_token        :string(255)
#  reset_password_sent_at      :datetime
#  remember_created_at         :datetime
#  sign_in_count               :integer          default(0)
#  current_sign_in_at          :datetime
#  last_sign_in_at             :datetime
#  current_sign_in_ip          :string(255)
#  last_sign_in_ip             :string(255)
#  created_at                  :datetime
#  updated_at                  :datetime
#  name                        :string(255)
#  admin                       :boolean          default(FALSE), not null
#  projects_limit              :integer          default(10)
#  skype                       :string(255)      default(""), not null
#  linkedin                    :string(255)      default(""), not null
#  twitter                     :string(255)      default(""), not null
#  authentication_token        :string(255)
#  theme_id                    :integer          default(1), not null
#  bio                         :string(255)
#  failed_attempts             :integer          default(0)
#  locked_at                   :datetime
#  username                    :string(255)
#  can_create_group            :boolean          default(TRUE), not null
#  can_create_team             :boolean          default(TRUE), not null
#  state                       :string(255)
#  color_scheme_id             :integer          default(1), not null
#  notification_level          :integer          default(1), not null
#  password_expires_at         :datetime
#  created_by_id               :integer
#  last_credential_check_at    :datetime
#  avatar                      :string(255)
#  confirmation_token          :string(255)
#  confirmed_at                :datetime
#  confirmation_sent_at        :datetime
#  unconfirmed_email           :string(255)
#  hide_no_ssh_key             :boolean          default(FALSE)
#  website_url                 :string(255)      default(""), not null
#  notification_email          :string(255)
#  hide_no_password            :boolean          default(FALSE)
#  password_automatically_set  :boolean          default(FALSE)
#  location                    :string(255)
#  encrypted_otp_secret        :string(255)
#  encrypted_otp_secret_iv     :string(255)
#  encrypted_otp_secret_salt   :string(255)
#  otp_required_for_login      :boolean          default(FALSE), not null
#  otp_backup_codes            :text
#  public_email                :string(255)      default(""), not null
#  dashboard                   :integer          default(0)
#  project_view                :integer          default(0)
#  consumed_timestep           :integer
#  layout                      :integer          default(0)
#  hide_project_limit          :boolean          default(FALSE)
#  unlock_token                :string
#  otp_grace_period_started_at :datetime
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class User < ActiveRecord::Base
  extend Gitlab::ConfigHelper

  include Gitlab::ConfigHelper
  include Gitlab::CurrentSettings
  include Referable
  include Sortable
  include CaseSensitivity
  include TokenAuthenticatable

  add_authentication_token_field :authentication_token

  default_value_for :admin, false
  default_value_for :can_create_group, gitlab_config.default_can_create_group
  default_value_for :can_create_team, false
  default_value_for :hide_no_ssh_key, false
  default_value_for :hide_no_password, false
  default_value_for :theme_id, gitlab_config.default_theme

  devise :two_factor_authenticatable,
         otp_secret_encryption_key: File.read(Rails.root.join('.secret')).chomp
  alias_attribute :two_factor_enabled, :otp_required_for_login

  devise :two_factor_backupable, otp_number_of_backup_codes: 10
  serialize :otp_backup_codes, JSON

  devise :lockable, :async, :recoverable, :rememberable, :trackable,
    :validatable, :omniauthable, :confirmable, :registerable

  attr_accessor :force_random_password

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  # Virtual attributes to define avatar cropping
  attr_accessor :avatar_crop_x, :avatar_crop_y, :avatar_crop_size

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace, -> { where type: nil }, dependent: :destroy, foreign_key: :owner_id, class_name: "Namespace"

  # Profile
  has_many :keys, dependent: :destroy
  has_many :emails, dependent: :destroy
  has_many :identities, dependent: :destroy, autosave: true

  # Groups
  has_many :members, dependent: :destroy
  has_many :project_members, source: 'ProjectMember'
  has_many :group_members, source: 'GroupMember'
  has_many :groups, through: :group_members
  has_many :owned_groups, -> { where members: { access_level: Gitlab::Access::OWNER } }, through: :group_members, source: :group
  has_many :masters_groups, -> { where members: { access_level: Gitlab::Access::MASTER } }, through: :group_members, source: :group

  # Projects
  has_many :groups_projects,          through: :groups, source: :projects
  has_many :personal_projects,        through: :namespace, source: :projects
  has_many :projects,                 through: :project_members
  has_many :created_projects,         foreign_key: :creator_id, class_name: 'Project'
  has_many :users_star_projects, dependent: :destroy
  has_many :starred_projects, through: :users_star_projects, source: :project

  has_many :snippets,                 dependent: :destroy, foreign_key: :author_id, class_name: "Snippet"
  has_many :project_members,          dependent: :destroy, class_name: 'ProjectMember'
  has_many :issues,                   dependent: :destroy, foreign_key: :author_id
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id
  has_many :events,                   dependent: :destroy, foreign_key: :author_id,   class_name: "Event"
  has_many :subscriptions,            dependent: :destroy
  has_many :recent_events, -> { order "id DESC" }, foreign_key: :author_id,   class_name: "Event"
  has_many :assigned_issues,          dependent: :destroy, foreign_key: :assignee_id, class_name: "Issue"
  has_many :assigned_merge_requests,  dependent: :destroy, foreign_key: :assignee_id, class_name: "MergeRequest"
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy
  has_one  :abuse_report,             dependent: :destroy
  has_many :spam_logs,                dependent: :destroy
  has_many :builds,                   dependent: :nullify, class_name: 'Ci::Build'
  has_many :todos,                    dependent: :destroy

  #
  # Validations
  #
  validates :name, presence: true
  validates :notification_email, presence: true, email: true
  validates :public_email, presence: true, uniqueness: true, email: true, allow_blank: true
  validates :bio, length: { maximum: 255 }, allow_blank: true
  validates :projects_limit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :username,
    namespace: true,
    presence: true,
    uniqueness: { case_sensitive: false }

  validates :notification_level, inclusion: { in: Notification.notification_levels }, presence: true
  validate :namespace_uniq, if: ->(user) { user.username_changed? }
  validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
  validate :unique_email, if: ->(user) { user.email_changed? }
  validate :owns_notification_email, if: ->(user) { user.notification_email_changed? }
  validate :owns_public_email, if: ->(user) { user.public_email_changed? }
  validates :avatar, file_size: { maximum: 200.kilobytes.to_i }

  validates :avatar_crop_x, :avatar_crop_y, :avatar_crop_size,
    numericality: { only_integer: true },
    presence: true,
    if: ->(user) { user.avatar? && user.avatar_changed? }

  before_validation :generate_password, on: :create
  before_validation :restricted_signup_domains, on: :create
  before_validation :sanitize_attrs
  before_validation :set_notification_email, if: ->(user) { user.email_changed? }
  before_validation :set_public_email, if: ->(user) { user.public_email_changed? }

  after_update :update_emails_with_primary_email, if: ->(user) { user.email_changed? }
  before_save :ensure_authentication_token
  after_save :ensure_namespace_correct
  after_initialize :set_projects_limit
  after_create :post_create_hook
  after_destroy :post_destroy_hook

  # User's Layout preference
  enum layout: [:fixed, :fluid]

  # User's Dashboard preference
  # Note: When adding an option, it MUST go on the end of the array.
  enum dashboard: [:projects, :stars, :project_activity, :starred_project_activity]

  # User's Project preference
  # Note: When adding an option, it MUST go on the end of the array.
  enum project_view: [:readme, :activity, :files]

  alias_attribute :private_token, :authentication_token

  delegate :path, to: :namespace, allow_nil: true, prefix: true

  state_machine :state, initial: :active do
    event :block do
      transition active: :blocked
      transition ldap_blocked: :blocked
    end

    event :ldap_block do
      transition active: :ldap_blocked
    end

    event :activate do
      transition blocked: :active
      transition ldap_blocked: :active
    end

    state :blocked, :ldap_blocked do
      def blocked?
        true
      end
    end
  end

  mount_uploader :avatar, AvatarUploader

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :blocked, -> { with_states(:blocked, :ldap_blocked) }
  scope :active, -> { with_state(:active) }
  scope :not_in_project, ->(project) { project.users.present? ? where("id not in (:ids)", ids: project.users.map(&:id) ) : all }
  scope :without_projects, -> { where('id NOT IN (SELECT DISTINCT(user_id) FROM members)') }
  scope :with_two_factor,    -> { where(two_factor_enabled: true) }
  scope :without_two_factor, -> { where(two_factor_enabled: false) }

  #
  # Class methods
  #
  class << self
    # Devise method overridden to allow sign in with email or username
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).find_by("lower(username) = :value OR lower(email) = :value", value: login.downcase)
      else
        find_by(conditions)
      end
    end

    def sort(method)
      case method.to_s
      when 'recent_sign_in' then reorder(last_sign_in_at: :desc)
      when 'oldest_sign_in' then reorder(last_sign_in_at: :asc)
      else
        order_by(method)
      end
    end

    # Find a User by their primary email or any associated secondary email
    def find_by_any_email(email)
      sql = 'SELECT *
      FROM users
      WHERE id IN (
        SELECT id FROM users WHERE email = :email
        UNION
        SELECT emails.user_id FROM emails WHERE email = :email
      )
      LIMIT 1;'

      User.find_by_sql([sql, { email: email }]).first
    end

    def filter(filter_name)
      case filter_name
      when 'admins'
        self.admins
      when 'blocked'
        self.blocked
      when 'two_factor_disabled'
        self.without_two_factor
      when 'two_factor_enabled'
        self.with_two_factor
      when 'wop'
        self.without_projects
      else
        self.active
      end
    end

    # Searches users matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      table   = arel_table
      pattern = "%#{query}%"

      where(
        table[:name].matches(pattern).
          or(table[:email].matches(pattern)).
          or(table[:username].matches(pattern))
      )
    end

    def by_login(login)
      return nil unless login

      if login.include?('@'.freeze)
        unscoped.iwhere(email: login).take
      else
        unscoped.iwhere(username: login).take
      end
    end

    def find_by_username!(username)
      find_by!('lower(username) = ?', username.downcase)
    end

    def by_username_or_id(name_or_id)
      find_by('users.username = ? OR users.id = ?', name_or_id.to_s, name_or_id.to_i)
    end

    def build_user(attrs = {})
      User.new(attrs)
    end

    def reference_prefix
      '@'
    end

    # Pattern used to extract `@user` user references from text
    def reference_pattern
      %r{
        #{Regexp.escape(reference_prefix)}
        (?<user>#{Gitlab::Regex::NAMESPACE_REGEX_STR})
      }x
    end
  end

  #
  # Instance methods
  #

  def to_param
    username
  end

  def to_reference(_from_project = nil)
    "#{self.class.reference_prefix}#{username}"
  end

  def notification
    @notification ||= Notification.new(self)
  end

  def generate_password
    if self.force_random_password
      self.password = self.password_confirmation = Devise.friendly_token.first(8)
    end
  end

  def generate_reset_token
    @reset_token, enc = Devise.token_generator.generate(self.class, :reset_password_token)

    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.now.utc

    @reset_token
  end

  def recently_sent_password_reset?
    reset_password_sent_at.present? && reset_password_sent_at >= 1.minute.ago
  end

  def disable_two_factor!
    update_attributes(
      two_factor_enabled:          false,
      encrypted_otp_secret:        nil,
      encrypted_otp_secret_iv:     nil,
      encrypted_otp_secret_salt:   nil,
      otp_grace_period_started_at: nil,
      otp_backup_codes:            nil
    )
  end

  def namespace_uniq
    # Return early if username already failed the first uniqueness validation
    return if self.errors.key?(:username) &&
      self.errors[:username].include?('has already been taken')

    namespace_name = self.username
    existing_namespace = Namespace.by_path(namespace_name)
    if existing_namespace && existing_namespace != self.namespace
      self.errors.add(:username, 'has already been taken')
    end
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, "only images allowed"
    end
  end

  def unique_email
    if !self.emails.exists?(email: self.email) && Email.exists?(email: self.email)
      self.errors.add(:email, 'has already been taken')
    end
  end

  def owns_notification_email
    self.errors.add(:notification_email, "is not an email you own") unless self.all_emails.include?(self.notification_email)
  end

  def owns_public_email
    return if self.public_email.blank?

    self.errors.add(:public_email, "is not an email you own") unless self.all_emails.include?(self.public_email)
  end

  def update_emails_with_primary_email
    primary_email_record = self.emails.find_by(email: self.email)
    if primary_email_record
      primary_email_record.destroy
      self.emails.create(email: self.email_was)

      self.update_secondary_emails!
    end
  end

  # Returns the groups a user has access to
  def authorized_groups
    union = Gitlab::SQL::Union.
      new([groups.select(:id), authorized_projects.select(:namespace_id)])

    Group.where("namespaces.id IN (#{union.to_sql})")
  end

  # Returns the groups a user is authorized to access.
  def authorized_projects
    Project.where("projects.id IN (#{projects_union.to_sql})")
  end

  def owned_projects
    @owned_projects ||=
      Project.where('namespace_id IN (?) OR namespace_id = ?',
                    owned_groups.select(:id), namespace.id).joins(:namespace)
  end

  # Team membership in authorized projects
  def tm_in_authorized_projects
    ProjectMember.where(source_id: authorized_projects.map(&:id), user_id: self.id)
  end

  def is_admin?
    admin
  end

  def require_ssh_key?
    keys.count == 0
  end

  def require_password?
    password_automatically_set? && !ldap_user?
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
    Ability.abilities
  end

  def can_select_namespace?
    several_namespaces? || admin
  end

  def can?(action, subject)
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

  def recent_push(project_id = nil)
    # Get push events not earlier than 2 hours ago
    events = recent_events.code_push.where("created_at > ?", Time.now - 2.hours)
    events = events.where(project_id: project_id) if project_id

    # Use the latest event that has not been pushed or merged recently
    events.recent.find do |event|
      project = Project.find_by_id(event.project_id)
      next unless project
      repo = project.repository

      if repo.branch_names.include?(event.branch_name)
        merge_requests = MergeRequest.where("created_at >= ?", event.created_at).
            where(source_project_id: project.id,
                  source_branch: event.branch_name)
        merge_requests.empty?
      end
    end
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
    project.project_member_by_id(self.id)
  end

  def already_forked?(project)
    !!fork_of(project)
  end

  def fork_of(project)
    links = ForkedProjectLink.where(forked_from_project_id: project, forked_to_project_id: personal_projects)

    if links.any?
      links.first.forked_to_project
    else
      nil
    end
  end

  def ldap_user?
    identities.exists?(["provider LIKE ? AND extern_uid IS NOT NULL", "ldap%"])
  end

  def ldap_identity
    @ldap_identity ||= identities.find_by(["provider LIKE ?", "ldap%"])
  end

  def project_deploy_keys
    DeployKey.unscoped.in_projects(self.authorized_projects.pluck(:id)).distinct(:id)
  end

  def accessible_deploy_keys
    @accessible_deploy_keys ||= begin
      key_ids = project_deploy_keys.pluck(:id)
      key_ids.push(*DeployKey.are_public.pluck(:id))
      DeployKey.where(id: key_ids)
    end
  end

  def created_by
    User.find_by(id: created_by_id) if created_by_id
  end

  def sanitize_attrs
    %w(name username skype linkedin twitter).each do |attr|
      value = self.send(attr)
      self.send("#{attr}=", Sanitize.clean(value)) if value.present?
    end
  end

  def set_notification_email
    if self.notification_email.blank? || !self.all_emails.include?(self.notification_email)
      self.notification_email = self.email
    end
  end

  def set_public_email
    if self.public_email.blank? || !self.all_emails.include?(self.public_email)
      self.public_email = ''
    end
  end

  def update_secondary_emails!
    self.set_notification_email
    self.set_public_email
    self.save if self.notification_email_changed? || self.public_email_changed?
  end

  def set_projects_limit
    connection_default_value_defined = new_record? && !projects_limit_changed?
    return unless self.projects_limit.nil? || connection_default_value_defined

    self.projects_limit = current_application_settings.default_projects_limit
  end

  def requires_ldap_check?
    if !Gitlab.config.ldap.enabled
      false
    elsif ldap_user?
      !last_credential_check_at || (last_credential_check_at + 1.hour) < Time.now
    else
      false
    end
  end

  def try_obtain_ldap_lease
    # After obtaining this lease LDAP checks will be blocked for 600 seconds
    # (10 minutes) for this user.
    lease = Gitlab::ExclusiveLease.new("user_ldap_check:#{id}", timeout: 600)
    lease.try_obtain
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
    return "http://#{website_url}" if website_url !~ /\Ahttps?:\/\//

    website_url
  end

  def short_website_url
    website_url.sub(/\Ahttps?:\/\//, '')
  end

  def all_ssh_keys
    keys.map(&:publishable_key)
  end

  def temp_oauth_email?
    email.start_with?('temp-email-for-oauth')
  end

  def avatar_url(size = nil, scale = 2)
    if avatar.present?
      [gitlab_config.url, avatar.url].join
    else
      GravatarService.new.execute(email, size, scale)
    end
  end

  def all_emails
    all_emails = []
    all_emails << self.email unless self.temp_oauth_email?
    all_emails.concat(self.emails.map(&:email))
    all_emails
  end

  def hook_attrs
    {
      name: name,
      username: username,
      avatar_url: avatar_url
    }
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
    notification_service.new_user(self, @reset_token) if self.created_by_id
    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_destroy_hook
    log_info("User \"#{self.name}\" (#{self.email})  was removed")
    system_hook_service.execute_hooks_for(self, :destroy)
  end

  def notification_service
    NotificationService.new
  end

  def log_info(message)
    Gitlab::AppLogger.info message
  end

  def system_hook_service
    SystemHooksService.new
  end

  def starred?(project)
    starred_projects.exists?(project.id)
  end

  def toggle_star(project)
    UsersStarProject.transaction do
      user_star_project = users_star_projects.
          where(project: project, user: self).lock(true).first

      if user_star_project
        user_star_project.destroy
      else
        UsersStarProject.create!(project: project, user: self)
      end
    end
  end

  def manageable_namespaces
    @manageable_namespaces ||= [namespace] + owned_groups + masters_groups
  end

  def namespaces
    namespace_ids = groups.pluck(:id)
    namespace_ids.push(namespace.id)
    Namespace.where(id: namespace_ids)
  end

  def oauth_authorized_tokens
    Doorkeeper::AccessToken.where(resource_owner_id: self.id, revoked_at: nil)
  end

  # Returns the projects a user contributed to in the last year.
  #
  # This method relies on a subquery as this performs significantly better
  # compared to a JOIN when coupled with, for example,
  # `Project.visible_to_user`. That is, consider the following code:
  #
  #     some_user.contributed_projects.visible_to_user(other_user)
  #
  # If this method were to use a JOIN the resulting query would take roughly 200
  # ms on a database with a similar size to GitLab.com's database. On the other
  # hand, using a subquery means we can get the exact same data in about 40 ms.
  def contributed_projects
    events = Event.select(:project_id).
      contributions.where(author_id: self).
      where("created_at > ?", Time.now - 1.year).
      uniq.
      reorder(nil)

    Project.where(id: events)
  end

  def restricted_signup_domains
    email_domains = current_application_settings.restricted_signup_domains

    unless email_domains.blank?
      match_found = email_domains.any? do |domain|
        escaped = Regexp.escape(domain).gsub('\*','.*?')
        regexp = Regexp.new "^#{escaped}$", Regexp::IGNORECASE
        email_domain = Mail::Address.new(self.email).domain
        email_domain =~ regexp
      end

      unless match_found
        self.errors.add :email,
                        'is not whitelisted. ' +
                        'Email domains valid for registration are: ' +
                        email_domains.join(', ')
        return false
      end
    end

    true
  end

  def can_be_removed?
    !solo_owned_groups.present?
  end

  def ci_authorized_runners
    @ci_authorized_runners ||= begin
      runner_ids = Ci::RunnerProject.
        where("ci_runner_projects.gl_project_id IN (#{ci_projects_union.to_sql})").
        select(:runner_id)
      Ci::Runner.specific.where(id: runner_ids)
    end
  end

  private

  def projects_union
    Gitlab::SQL::Union.new([personal_projects.select(:id),
                            groups_projects.select(:id),
                            projects.select(:id)])
  end

  def ci_projects_union
    scope  = { access_level: [Gitlab::Access::MASTER, Gitlab::Access::OWNER] }
    groups = groups_projects.where(members: scope)
    other  = projects.where(members: scope)

    Gitlab::SQL::Union.new([personal_projects.select(:id), groups.select(:id),
                            other.select(:id)])
  end

  # Added according to https://github.com/plataformatec/devise/blob/7df57d5081f9884849ca15e4fde179ef164a575f/README.md#activejob-integration
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
