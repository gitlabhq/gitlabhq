require 'carrierwave/orm/activerecord'

class User < ActiveRecord::Base
  extend Gitlab::ConfigHelper

  include Gitlab::ConfigHelper
  include Gitlab::CurrentSettings
  include Referable
  include Sortable
  include CaseSensitivity
  include TokenAuthenticatable

  DEFAULT_NOTIFICATION_LEVEL = :participating

  add_authentication_token_field :authentication_token
  add_authentication_token_field :incoming_email_token

  default_value_for :admin, false
  default_value_for(:external) { current_application_settings.user_default_external }
  default_value_for :can_create_group, gitlab_config.default_can_create_group
  default_value_for :can_create_team, false
  default_value_for :hide_no_ssh_key, false
  default_value_for :hide_no_password, false
  default_value_for :theme_id, gitlab_config.default_theme

  attr_encrypted :otp_secret,
    key:       Gitlab::Application.secrets.otp_key_base,
    mode:      :per_attribute_iv_and_salt,
    insecure_mode: true,
    algorithm: 'aes-256-cbc'

  devise :two_factor_authenticatable,
         otp_secret_encryption_key: Gitlab::Application.secrets.otp_key_base

  devise :two_factor_backupable, otp_number_of_backup_codes: 10
  serialize :otp_backup_codes, JSON

  devise :lockable, :recoverable, :rememberable, :trackable,
    :validatable, :omniauthable, :confirmable, :registerable

  attr_accessor :force_random_password

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace, -> { where type: nil }, dependent: :destroy, foreign_key: :owner_id

  # Profile
  has_many :keys, dependent: :destroy
  has_many :emails, dependent: :destroy
  has_many :personal_access_tokens, dependent: :destroy
  has_many :identities, dependent: :destroy, autosave: true
  has_many :u2f_registrations, dependent: :destroy
  has_many :chat_names, dependent: :destroy

  # Groups
  has_many :members, dependent: :destroy
  has_many :group_members, -> { where(requested_at: nil) }, dependent: :destroy, source: 'GroupMember'
  has_many :groups, through: :group_members
  has_many :owned_groups, -> { where members: { access_level: Gitlab::Access::OWNER } }, through: :group_members, source: :group
  has_many :masters_groups, -> { where members: { access_level: Gitlab::Access::MASTER } }, through: :group_members, source: :group

  # Projects
  has_many :groups_projects,          through: :groups, source: :projects
  has_many :personal_projects,        through: :namespace, source: :projects
  has_many :project_members, -> { where(requested_at: nil) }, dependent: :destroy
  has_many :projects,                 through: :project_members
  has_many :created_projects,         foreign_key: :creator_id, class_name: 'Project'
  has_many :users_star_projects, dependent: :destroy
  has_many :starred_projects, through: :users_star_projects, source: :project
  has_many :project_authorizations, dependent: :destroy
  has_many :authorized_projects, through: :project_authorizations, source: :project

  has_many :snippets,                 dependent: :destroy, foreign_key: :author_id
  has_many :issues,                   dependent: :destroy, foreign_key: :author_id
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id
  has_many :events,                   dependent: :destroy, foreign_key: :author_id
  has_many :subscriptions,            dependent: :destroy
  has_many :recent_events, -> { order "id DESC" }, foreign_key: :author_id,   class_name: "Event"
  has_many :assigned_issues,          dependent: :destroy, foreign_key: :assignee_id, class_name: "Issue"
  has_many :assigned_merge_requests,  dependent: :destroy, foreign_key: :assignee_id, class_name: "MergeRequest"
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy
  has_one  :abuse_report,             dependent: :destroy
  has_many :spam_logs,                dependent: :destroy
  has_many :builds,                   dependent: :nullify, class_name: 'Ci::Build'
  has_many :pipelines,                dependent: :nullify, class_name: 'Ci::Pipeline'
  has_many :todos,                    dependent: :destroy
  has_many :notification_settings,    dependent: :destroy
  has_many :award_emoji,              dependent: :destroy

  #
  # Validations
  #
  # Note: devise :validatable above adds validations for :email and :password
  validates :name, presence: true
  validates :notification_email, presence: true
  validates :notification_email, email: true, if: ->(user) { user.notification_email != user.email }
  validates :public_email, presence: true, uniqueness: true, email: true, allow_blank: true
  validates :bio, length: { maximum: 255 }, allow_blank: true
  validates :projects_limit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :username,
    namespace: true,
    presence: true,
    uniqueness: { case_sensitive: false }

  validate :namespace_uniq, if: ->(user) { user.username_changed? }
  validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
  validate :unique_email, if: ->(user) { user.email_changed? }
  validate :owns_notification_email, if: ->(user) { user.notification_email_changed? }
  validate :owns_public_email, if: ->(user) { user.public_email_changed? }
  validates :avatar, file_size: { maximum: 200.kilobytes.to_i }

  before_validation :generate_password, on: :create
  before_validation :signup_domain_valid?, on: :create
  before_validation :sanitize_attrs
  before_validation :set_notification_email, if: ->(user) { user.email_changed? }
  before_validation :set_public_email, if: ->(user) { user.public_email_changed? }

  after_update :update_emails_with_primary_email, if: ->(user) { user.email_changed? }
  before_save :ensure_authentication_token, :ensure_incoming_email_token
  before_save :ensure_external_user_rights
  after_save :ensure_namespace_correct
  after_initialize :set_projects_limit
  before_create :check_confirmation_email
  after_create :post_create_hook
  after_destroy :post_destroy_hook

  # User's Layout preference
  enum layout: [:fixed, :fluid]

  # User's Dashboard preference
  # Note: When adding an option, it MUST go on the end of the array.
  enum dashboard: [:projects, :stars, :project_activity, :starred_project_activity, :groups, :todos]

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
  scope :external, -> { where(external: true) }
  scope :active, -> { with_state(:active) }
  scope :not_in_project, ->(project) { project.users.present? ? where("id not in (:ids)", ids: project.users.map(&:id) ) : all }
  scope :without_projects, -> { where('id NOT IN (SELECT DISTINCT(user_id) FROM members WHERE user_id IS NOT NULL AND requested_at IS NULL)') }
  scope :todo_authors, ->(user_id, state) { where(id: Todo.where(user_id: user_id, state: state).select(:author_id)) }

  def self.with_two_factor
    joins("LEFT OUTER JOIN u2f_registrations AS u2f ON u2f.user_id = users.id").
      where("u2f.id IS NOT NULL OR otp_required_for_login = ?", true).distinct(arel_table[:id])
  end

  def self.without_two_factor
    joins("LEFT OUTER JOIN u2f_registrations AS u2f ON u2f.user_id = users.id").
      where("u2f.id IS NULL AND otp_required_for_login = ?", false)
  end

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
      when 'external'
        self.external
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

    # searches user by given pattern
    # it compares name, email, username fields and user's secondary emails with given pattern
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.

    def search_with_secondary_emails(query)
      table = arel_table
      email_table = Email.arel_table
      pattern = "%#{query}%"
      matched_by_emails_user_ids = email_table.project(email_table[:user_id]).where(email_table[:email].matches(pattern))

      where(
        table[:name].matches(pattern).
          or(table[:email].matches(pattern)).
          or(table[:username].matches(pattern)).
          or(table[:id].in(matched_by_emails_user_ids))
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

    def find_by_personal_access_token(token_string)
      personal_access_token = PersonalAccessToken.active.find_by_token(token_string) if token_string
      personal_access_token.user if personal_access_token
    end

    def by_username_or_id(name_or_id)
      find_by('users.username = ? OR users.id = ?', name_or_id.to_s, name_or_id.to_i)
    end

    # Returns a user for the given SSH key.
    def find_by_ssh_key_id(key_id)
      find_by(id: Key.unscoped.select(:user_id).where(id: key_id))
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

  def to_reference(_from_project = nil, _target_project = nil)
    "#{self.class.reference_prefix}#{username}"
  end

  def generate_password
    if self.force_random_password
      self.password = self.password_confirmation = Devise.friendly_token.first(Devise.password_length.min)
    end
  end

  def generate_reset_token
    @reset_token, enc = Devise.token_generator.generate(self.class, :reset_password_token)

    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.now.utc

    @reset_token
  end

  def check_confirmation_email
    skip_confirmation! unless current_application_settings.send_user_confirmation_email
  end

  def recently_sent_password_reset?
    reset_password_sent_at.present? && reset_password_sent_at >= 1.minute.ago
  end

  def disable_two_factor!
    transaction do
      update_attributes(
        otp_required_for_login:      false,
        encrypted_otp_secret:        nil,
        encrypted_otp_secret_iv:     nil,
        encrypted_otp_secret_salt:   nil,
        otp_grace_period_started_at: nil,
        otp_backup_codes:            nil
      )
      self.u2f_registrations.destroy_all
    end
  end

  def two_factor_enabled?
    two_factor_otp_enabled? || two_factor_u2f_enabled?
  end

  def two_factor_otp_enabled?
    self.otp_required_for_login?
  end

  def two_factor_u2f_enabled?
    self.u2f_registrations.exists?
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
    return if self.temp_oauth_email?

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

  def refresh_authorized_projects
    transaction do
      project_authorizations.delete_all

      # project_authorizations_union can return multiple records for the same
      # project/user with different access_level so we take row with the maximum
      # access_level
      project_authorizations.connection.execute <<-SQL
      INSERT INTO project_authorizations (user_id, project_id, access_level)
      SELECT user_id, project_id, MAX(access_level) AS access_level
      FROM (#{project_authorizations_union.to_sql}) sub
      GROUP BY user_id, project_id
      SQL

      unless authorized_projects_populated
        update_column(:authorized_projects_populated, true)
      end
    end
  end

  def authorized_projects(min_access_level = nil)
    refresh_authorized_projects unless authorized_projects_populated

    # We're overriding an association, so explicitly call super with no arguments or it would be passed as `force_reload` to the association
    projects = super()
    projects = projects.where('project_authorizations.access_level >= ?', min_access_level) if min_access_level

    projects
  end

  def authorized_project?(project, min_access_level = nil)
    authorized_projects(min_access_level).exists?({ id: project.id })
  end

  # Returns the projects this user has reporter (or greater) access to, limited
  # to at most the given projects.
  #
  # This method is useful when you have a list of projects and want to
  # efficiently check to which of these projects the user has at least reporter
  # access.
  def projects_with_reporter_access_limited_to(projects)
    authorized_projects(Gitlab::Access::REPORTER).where(id: projects)
  end

  def viewable_starred_projects
    starred_projects.where("projects.visibility_level IN (?) OR projects.id IN (?)",
                           [Project::PUBLIC, Project::INTERNAL],
                           authorized_projects.select(:project_id))
  end

  def owned_projects
    @owned_projects ||=
      Project.where('namespace_id IN (?) OR namespace_id = ?',
                    owned_groups.select(:id), namespace.id).joins(:namespace)
  end

  # Returns projects which user can admin issues on (for example to move an issue to that project).
  #
  # This logic is duplicated from `Ability#project_abilities` into a SQL form.
  def projects_where_can_admin_issues
    authorized_projects(Gitlab::Access::REPORTER).non_archived.with_issues_enabled
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

  def can_select_namespace?
    several_namespaces? || admin
  end

  def can?(action, subject)
    Ability.allowed?(self, action, subject)
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

  def recent_push(project_ids = nil)
    # Get push events not earlier than 2 hours ago
    events = recent_events.code_push.where("created_at > ?", Time.now - 2.hours)
    events = events.where(project_id: project_ids) if project_ids

    # Use the latest event that has not been pushed or merged recently
    events.recent.find do |event|
      project = Project.find_by_id(event.project_id)
      next unless project

      if project.repository.branch_exists?(event.branch_name)
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
    # `User.select(:id)` raises
    # `ActiveModel::MissingAttributeError: missing attribute: projects_limit`
    # without this safeguard!
    return unless self.has_attribute?(:projects_limit)

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
    if self[:avatar].present?
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

  def notification_settings_for(source)
    notification_settings.find_or_initialize_by(source: source)
  end

  # Lazy load global notification setting
  # Initializes User setting with Participating level if setting not persisted
  def global_notification_setting
    return @global_notification_setting if defined?(@global_notification_setting)

    @global_notification_setting = notification_settings.find_or_initialize_by(source: nil)
    @global_notification_setting.update_attributes(level: NotificationSetting.levels[DEFAULT_NOTIFICATION_LEVEL]) unless @global_notification_setting.persisted?

    @global_notification_setting
  end

  def assigned_open_merge_request_count(force: false)
    Rails.cache.fetch(['users', id, 'assigned_open_merge_request_count'], force: force) do
      assigned_merge_requests.opened.count
    end
  end

  def assigned_open_issues_count(force: false)
    Rails.cache.fetch(['users', id, 'assigned_open_issues_count'], force: force) do
      assigned_issues.opened.count
    end
  end

  def update_cache_counts
    assigned_open_merge_request_count(force: true)
    assigned_open_issues_count(force: true)
  end

  def todos_done_count(force: false)
    Rails.cache.fetch(['users', id, 'todos_done_count'], force: force) do
      TodosFinder.new(self, state: :done).execute.count
    end
  end

  def todos_pending_count(force: false)
    Rails.cache.fetch(['users', id, 'todos_pending_count'], force: force) do
      TodosFinder.new(self, state: :pending).execute.count
    end
  end

  def update_todos_count_cache
    todos_done_count(force: true)
    todos_pending_count(force: true)
  end

  # This is copied from Devise::Models::Lockable#valid_for_authentication?, as our auth
  # flow means we don't call that automatically (and can't conveniently do so).
  #
  # See:
  #   <https://github.com/plataformatec/devise/blob/v4.0.0/lib/devise/models/lockable.rb#L92>
  #
  def increment_failed_attempts!
    self.failed_attempts ||= 0
    self.failed_attempts += 1
    if attempts_exceeded?
      lock_access! unless access_locked?
    else
      save(validate: false)
    end
  end

  private

  # Returns a union query of projects that the user is authorized to access
  def project_authorizations_union
    relations = [
      personal_projects.select("#{id} AS user_id, projects.id AS project_id, #{Gitlab::Access::OWNER} AS access_level"),
      groups_projects.select_for_project_authorization,
      projects.select_for_project_authorization,
      groups.joins(:shared_projects).select_for_project_authorization
    ]

    Gitlab::SQL::Union.new(relations)
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

  def ensure_external_user_rights
    return unless self.external?

    self.can_create_group   = false
    self.projects_limit     = 0
  end

  def signup_domain_valid?
    valid = true
    error = nil

    if current_application_settings.domain_blacklist_enabled?
      blocked_domains = current_application_settings.domain_blacklist
      if domain_matches?(blocked_domains, self.email)
        error = 'is not from an allowed domain.'
        valid = false
      end
    end

    allowed_domains = current_application_settings.domain_whitelist
    unless allowed_domains.blank?
      if domain_matches?(allowed_domains, self.email)
        valid = true
      else
        error = "domain is not authorized for sign-up"
        valid = false
      end
    end

    self.errors.add(:email, error) unless valid

    valid
  end

  def domain_matches?(email_domains, email)
    signup_domain = Mail::Address.new(email).domain
    email_domains.any? do |domain|
      escaped = Regexp.escape(domain).gsub('\*', '.*?')
      regexp = Regexp.new "^#{escaped}$", Regexp::IGNORECASE
      signup_domain =~ regexp
    end
  end

  def generate_token(token_field)
    if token_field == :incoming_email_token
      # Needs to be all lowercase and alphanumeric because it's gonna be used in an email address.
      SecureRandom.hex.to_i(16).to_s(36)
    else
      super
    end
  end
end
