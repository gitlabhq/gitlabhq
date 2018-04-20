require 'carrierwave/orm/activerecord'

class User < ActiveRecord::Base
  extend Gitlab::ConfigHelper

  include Gitlab::ConfigHelper
  include Gitlab::SQL::Pattern
  include AfterCommitQueue
  include Avatarable
  include Referable
  include Sortable
  include CaseSensitivity
  include TokenAuthenticatable
  include IgnorableColumn
  include FeatureGate
  include CreatedAtFilterable
  include IgnorableColumn
  include BulkMemberAccessLoad
  include BlocksJsonSerialization

  DEFAULT_NOTIFICATION_LEVEL = :participating

  ignore_column :external_email
  ignore_column :email_provider
  ignore_column :authentication_token

  add_authentication_token_field :incoming_email_token
  add_authentication_token_field :rss_token

  default_value_for :admin, false
  default_value_for(:external) { Gitlab::CurrentSettings.user_default_external }
  default_value_for :can_create_group, gitlab_config.default_can_create_group
  default_value_for :can_create_team, false
  default_value_for :hide_no_ssh_key, false
  default_value_for :hide_no_password, false
  default_value_for :project_view, :files
  default_value_for :notified_of_own_activity, false
  default_value_for :preferred_language, I18n.default_locale
  default_value_for :theme_id, gitlab_config.default_theme

  attr_encrypted :otp_secret,
    key:       Gitlab::Application.secrets.otp_key_base,
    mode:      :per_attribute_iv_and_salt,
    insecure_mode: true,
    algorithm: 'aes-256-cbc'

  devise :two_factor_authenticatable,
         otp_secret_encryption_key: Gitlab::Application.secrets.otp_key_base

  devise :two_factor_backupable, otp_number_of_backup_codes: 10
  serialize :otp_backup_codes, JSON # rubocop:disable Cop/ActiveRecordSerialize

  devise :lockable, :recoverable, :rememberable, :trackable,
         :validatable, :omniauthable, :confirmable, :registerable

  BLOCKED_MESSAGE = "Your account has been blocked. Please contact your GitLab " \
                    "administrator if you think this is an error.".freeze

  # Override Devise::Models::Trackable#update_tracked_fields!
  # to limit database writes to at most once every hour
  def update_tracked_fields!(request)
    return if Gitlab::Database.read_only?

    update_tracked_fields(request)

    lease = Gitlab::ExclusiveLease.new("user_update_tracked_fields:#{id}", timeout: 1.hour.to_i)
    return unless lease.try_obtain

    Users::UpdateService.new(self, user: self).execute(validate: false)
  end

  attr_accessor :force_random_password

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace, -> { where(type: nil) }, dependent: :destroy, foreign_key: :owner_id, inverse_of: :owner, autosave: true # rubocop:disable Cop/ActiveRecordDependent

  # Profile
  has_many :keys, -> { where(type: ['Key', nil]) }, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :deploy_keys, -> { where(type: 'DeployKey') }, dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
  has_many :gpg_keys

  has_many :emails, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :personal_access_tokens, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :identities, dependent: :destroy, autosave: true # rubocop:disable Cop/ActiveRecordDependent
  has_many :u2f_registrations, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :chat_names, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :user_synced_attributes_metadata, autosave: true

  # Groups
  has_many :members
  has_many :group_members, -> { where(requested_at: nil) }, source: 'GroupMember'
  has_many :groups, through: :group_members
  has_many :owned_groups, -> { where(members: { access_level: Gitlab::Access::OWNER }) }, through: :group_members, source: :group
  has_many :masters_groups, -> { where(members: { access_level: Gitlab::Access::MASTER }) }, through: :group_members, source: :group

  # Projects
  has_many :groups_projects,          through: :groups, source: :projects
  has_many :personal_projects,        through: :namespace, source: :projects
  has_many :project_members, -> { where(requested_at: nil) }
  has_many :projects,                 through: :project_members
  has_many :created_projects,         foreign_key: :creator_id, class_name: 'Project'
  has_many :users_star_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :starred_projects, through: :users_star_projects, source: :project
  has_many :project_authorizations
  has_many :authorized_projects, through: :project_authorizations, source: :project

  has_many :user_interacted_projects
  has_many :project_interactions, through: :user_interacted_projects, source: :project, class_name: 'Project'

  has_many :snippets,                 dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :issues,                   dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :events,                   dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :subscriptions,            dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one  :abuse_report,             dependent: :destroy, foreign_key: :user_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :reported_abuse_reports,   dependent: :destroy, foreign_key: :reporter_id, class_name: "AbuseReport" # rubocop:disable Cop/ActiveRecordDependent
  has_many :spam_logs,                dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :builds,                   dependent: :nullify, class_name: 'Ci::Build' # rubocop:disable Cop/ActiveRecordDependent
  has_many :pipelines,                dependent: :nullify, class_name: 'Ci::Pipeline' # rubocop:disable Cop/ActiveRecordDependent
  has_many :todos
  has_many :notification_settings,    dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :award_emoji,              dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :triggers,                 dependent: :destroy, class_name: 'Ci::Trigger', foreign_key: :owner_id # rubocop:disable Cop/ActiveRecordDependent

  has_many :issue_assignees
  has_many :assigned_issues, class_name: "Issue", through: :issue_assignees, source: :issue
  has_many :assigned_merge_requests,  dependent: :nullify, foreign_key: :assignee_id, class_name: "MergeRequest" # rubocop:disable Cop/ActiveRecordDependent

  has_many :custom_attributes, class_name: 'UserCustomAttribute'
  has_many :callouts, class_name: 'UserCallout'
  has_many :uploads, as: :model, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  #
  # Validations
  #
  # Note: devise :validatable above adds validations for :email and :password
  validates :name, presence: true
  validates :email, confirmation: true
  validates :notification_email, presence: true
  validates :notification_email, email: true, if: ->(user) { user.notification_email != user.email }
  validates :public_email, presence: true, uniqueness: true, email: true, allow_blank: true
  validates :bio, length: { maximum: 255 }, allow_blank: true
  validates :projects_limit,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: Gitlab::Database::MAX_INT_VALUE }
  validates :username, presence: true

  validates :namespace, presence: true
  validate :namespace_move_dir_allowed, if: :username_changed?

  validate :unique_email, if: :email_changed?
  validate :owns_notification_email, if: :notification_email_changed?
  validate :owns_public_email, if: :public_email_changed?
  validate :signup_domain_valid?, on: :create, if: ->(user) { !user.created_by_id }

  before_validation :sanitize_attrs
  before_validation :set_notification_email, if: :email_changed?
  before_save :set_notification_email, if: :email_changed? # in case validation is skipped
  before_validation :set_public_email, if: :public_email_changed?
  before_save :set_public_email, if: :public_email_changed? # in case validation is skipped
  before_save :ensure_incoming_email_token
  before_save :ensure_user_rights_and_limits, if: ->(user) { user.new_record? || user.external_changed? }
  before_save :skip_reconfirmation!, if: ->(user) { user.email_changed? && user.read_only_attribute?(:email) }
  before_save :check_for_verified_email, if: ->(user) { user.email_changed? && !user.new_record? }
  before_validation :ensure_namespace_correct
  before_save :ensure_namespace_correct # in case validation is skipped
  after_validation :set_username_errors
  after_update :username_changed_hook, if: :username_changed?
  after_destroy :post_destroy_hook
  after_destroy :remove_key_cache
  after_commit :update_emails_with_primary_email, on: :update, if: -> { previous_changes.key?('email') }
  after_commit :update_invalid_gpg_signatures, on: :update, if: -> { previous_changes.key?('email') }

  after_initialize :set_projects_limit

  # User's Layout preference
  enum layout: [:fixed, :fluid]

  # User's Dashboard preference
  # Note: When adding an option, it MUST go on the end of the array.
  enum dashboard: [:projects, :stars, :project_activity, :starred_project_activity, :groups, :todos, :issues, :merge_requests]

  # User's Project preference
  # Note: When adding an option, it MUST go on the end of the array.
  enum project_view: [:readme, :activity, :files]

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

      def active_for_authentication?
        false
      end

      def inactive_message
        BLOCKED_MESSAGE
      end
    end
  end

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :blocked, -> { with_states(:blocked, :ldap_blocked) }
  scope :external, -> { where(external: true) }
  scope :active, -> { with_state(:active).non_internal }
  scope :without_projects, -> { where('id NOT IN (SELECT DISTINCT(user_id) FROM members WHERE user_id IS NOT NULL AND requested_at IS NULL)') }
  scope :todo_authors, ->(user_id, state) { where(id: Todo.where(user_id: user_id, state: state).select(:author_id)) }
  scope :order_recent_sign_in, -> { reorder(Gitlab::Database.nulls_last_order('current_sign_in_at', 'DESC')) }
  scope :order_oldest_sign_in, -> { reorder(Gitlab::Database.nulls_last_order('current_sign_in_at', 'ASC')) }

  def self.with_two_factor
    joins("LEFT OUTER JOIN u2f_registrations AS u2f ON u2f.user_id = users.id")
      .where("u2f.id IS NOT NULL OR otp_required_for_login = ?", true).distinct(arel_table[:id])
  end

  def self.without_two_factor
    joins("LEFT OUTER JOIN u2f_registrations AS u2f ON u2f.user_id = users.id")
      .where("u2f.id IS NULL AND otp_required_for_login = ?", false)
  end

  #
  # Class methods
  #
  class << self
    # Devise method overridden to allow sign in with email or username
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).find_by("lower(username) = :value OR lower(email) = :value", value: login.downcase.strip)
      else
        find_by(conditions)
      end
    end

    def sort_by_attribute(method)
      order_method = method || 'id_desc'

      case order_method.to_s
      when 'recent_sign_in' then order_recent_sign_in
      when 'oldest_sign_in' then order_oldest_sign_in
      else
        order_by(order_method)
      end
    end

    def for_github_id(id)
      joins(:identities).merge(Identity.with_extern_uid(:github, id))
    end

    # Find a User by their primary email or any associated secondary email
    def find_by_any_email(email)
      by_any_email(email).take
    end

    # Returns a relation containing all the users for the given Email address
    def by_any_email(email)
      users = where(email: email)
      emails = joins(:emails).where(emails: { email: email })
      union = Gitlab::SQL::Union.new([users, emails])

      from("(#{union.to_sql}) #{table_name}")
    end

    def filter(filter_name)
      case filter_name
      when 'admins'
        admins
      when 'blocked'
        blocked
      when 'two_factor_disabled'
        without_two_factor
      when 'two_factor_enabled'
        with_two_factor
      when 'wop'
        without_projects
      when 'external'
        external
      else
        active
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
      return none if query.blank?

      query = query.downcase

      order = <<~SQL
        CASE
          WHEN users.name = %{query} THEN 0
          WHEN users.username = %{query} THEN 1
          WHEN users.email = %{query} THEN 2
          ELSE 3
        END
      SQL

      where(
        fuzzy_arel_match(:name, query, lower_exact_match: true)
          .or(fuzzy_arel_match(:username, query, lower_exact_match: true))
          .or(arel_table[:email].eq(query))
      ).reorder(order % { query: ActiveRecord::Base.connection.quote(query) }, :name)
    end

    # searches user by given pattern
    # it compares name, email, username fields and user's secondary emails with given pattern
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.

    def search_with_secondary_emails(query)
      return none if query.blank?

      query = query.downcase

      email_table = Email.arel_table
      matched_by_emails_user_ids = email_table
        .project(email_table[:user_id])
        .where(email_table[:email].eq(query))

      where(
        fuzzy_arel_match(:name, query)
          .or(fuzzy_arel_match(:username, query))
          .or(arel_table[:email].eq(query))
          .or(arel_table[:id].in(matched_by_emails_user_ids))
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

    def find_by_username(username)
      iwhere(username: username).take
    end

    def find_by_username!(username)
      iwhere(username: username).take!
    end

    def find_by_personal_access_token(token_string)
      return unless token_string

      PersonalAccessTokensFinder.new(state: 'active').find_by(token: token_string)&.user
    end

    # Returns a user for the given SSH key.
    def find_by_ssh_key_id(key_id)
      Key.find_by(id: key_id)&.user
    end

    def find_by_full_path(path, follow_redirects: false)
      namespace = Namespace.for_user.find_by_full_path(path, follow_redirects: follow_redirects)
      namespace&.owner
    end

    def reference_prefix
      '@'
    end

    # Pattern used to extract `@user` user references from text
    def reference_pattern
      %r{
        (?<!\w)
        #{Regexp.escape(reference_prefix)}
        (?<user>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
      }x
    end

    # Return (create if necessary) the ghost user. The ghost user
    # owns records previously belonging to deleted users.
    def ghost
      email = 'ghost%s@example.com'
      unique_internal(where(ghost: true), 'ghost', email) do |u|
        u.bio = 'This is a "Ghost User", created to hold all issues authored by users that have since been deleted. This user cannot be removed.'
        u.name = 'Ghost User'
      end
    end
  end

  def full_path
    username
  end

  def self.internal_attributes
    [:ghost]
  end

  def internal?
    self.class.internal_attributes.any? { |a| self[a] }
  end

  def self.internal
    where(Hash[internal_attributes.zip([true] * internal_attributes.size)])
  end

  def self.non_internal
    where(internal_attributes.map { |attr| "#{attr} IS NOT TRUE" }.join(" AND "))
  end

  #
  # Instance methods
  #

  def to_param
    username
  end

  def to_reference(_from = nil, target_project: nil, full: nil)
    "#{self.class.reference_prefix}#{username}"
  end

  def skip_confirmation=(bool)
    skip_confirmation! if bool
  end

  def skip_reconfirmation=(bool)
    skip_reconfirmation! if bool
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

  def remember_me!
    super if ::Gitlab::Database.read_write?
  end

  def forget_me!
    super if ::Gitlab::Database.read_write?
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
    otp_required_for_login?
  end

  def two_factor_u2f_enabled?
    if u2f_registrations.loaded?
      u2f_registrations.any?
    else
      u2f_registrations.exists?
    end
  end

  def namespace_move_dir_allowed
    if namespace&.any_project_has_container_registry_tags?
      errors.add(:username, 'cannot be changed if a personal project has container registry tags.')
    end
  end

  def unique_email
    if !emails.exists?(email: email) && Email.exists?(email: email)
      errors.add(:email, 'has already been taken')
    end
  end

  def owns_notification_email
    return if temp_oauth_email?

    errors.add(:notification_email, "is not an email you own") unless all_emails.include?(notification_email)
  end

  def owns_public_email
    return if public_email.blank?

    errors.add(:public_email, "is not an email you own") unless all_emails.include?(public_email)
  end

  # see if the new email is already a verified secondary email
  def check_for_verified_email
    skip_reconfirmation! if emails.confirmed.where(email: self.email).any?
  end

  # Note: the use of the Emails services will cause `saves` on the user object, running
  # through the callbacks again and can have side effects, such as the `previous_changes`
  # hash and `_was` variables getting munged.
  # By using an `after_commit` instead of `after_update`, we avoid the recursive callback
  # scenario, though it then requires us to use the `previous_changes` hash
  def update_emails_with_primary_email
    previous_email = previous_changes[:email][0]  # grab this before the DestroyService is called
    primary_email_record = emails.find_by(email: email)
    Emails::DestroyService.new(self, user: self).execute(primary_email_record) if primary_email_record

    # the original primary email was confirmed, and we want that to carry over.  We don't
    # have access to the original confirmation values at this point, so just set confirmed_at
    Emails::CreateService.new(self, user: self, email: previous_email).execute(confirmed_at: confirmed_at)
  end

  def update_invalid_gpg_signatures
    gpg_keys.each(&:update_invalid_gpg_signatures)
  end

  # Returns the groups a user has access to, either through a membership or a project authorization
  def authorized_groups
    union = Gitlab::SQL::Union
      .new([groups.select(:id), authorized_projects.select(:namespace_id)])

    Group.where("namespaces.id IN (#{union.to_sql})") # rubocop:disable GitlabSecurity/SqlInjection
  end

  # Returns the groups a user is a member of, either directly or through a parent group
  def membership_groups
    Gitlab::GroupHierarchy.new(groups).base_and_descendants
  end

  # Returns a relation of groups the user has access to, including their parent
  # and child groups (recursively).
  def all_expanded_groups
    Gitlab::GroupHierarchy.new(groups).all_groups
  end

  def expanded_groups_requiring_two_factor_authentication
    all_expanded_groups.where(require_two_factor_authentication: true)
  end

  def refresh_authorized_projects
    Users::RefreshAuthorizedProjectsService.new(self).execute
  end

  def remove_project_authorizations(project_ids)
    project_authorizations.where(project_id: project_ids).delete_all
  end

  def authorized_projects(min_access_level = nil)
    # We're overriding an association, so explicitly call super with no
    # arguments or it would be passed as `force_reload` to the association
    projects = super()

    if min_access_level
      projects = projects
        .where('project_authorizations.access_level >= ?', min_access_level)
    end

    projects
  end

  def authorized_project?(project, min_access_level = nil)
    authorized_projects(min_access_level).exists?({ id: project.id })
  end

  # Typically used in conjunction with projects table to get projects
  # a user has been given access to.
  #
  # Example use:
  # `Project.where('EXISTS(?)', user.authorizations_for_projects)`
  def authorizations_for_projects
    project_authorizations.select(1).where('project_authorizations.project_id = projects.id')
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

  def owned_projects
    @owned_projects ||= Project.from("(#{owned_projects_union.to_sql}) AS projects")
  end

  # Returns projects which user can admin issues on (for example to move an issue to that project).
  #
  # This logic is duplicated from `Ability#project_abilities` into a SQL form.
  def projects_where_can_admin_issues
    authorized_projects(Gitlab::Access::REPORTER).non_archived.with_issues_enabled
  end

  def require_ssh_key?
    count = Users::KeysCountService.new(self).count

    count.zero? && Gitlab::ProtocolAccess.allowed?('ssh')
  end

  def require_password_creation_for_web?
    allow_password_authentication_for_web? && password_automatically_set?
  end

  def require_password_creation_for_git?
    allow_password_authentication_for_git? && password_automatically_set?
  end

  def require_personal_access_token_creation_for_git_auth?
    return false if allow_password_authentication_for_git? || ldap_user?

    PersonalAccessTokensFinder.new(user: self, impersonation: false, state: 'active').execute.none?
  end

  def require_extra_setup_for_git_auth?
    require_password_creation_for_git? || require_personal_access_token_creation_for_git_auth?
  end

  def allow_password_authentication?
    allow_password_authentication_for_web? || allow_password_authentication_for_git?
  end

  def allow_password_authentication_for_web?
    Gitlab::CurrentSettings.password_authentication_enabled_for_web? && !ldap_user?
  end

  def allow_password_authentication_for_git?
    Gitlab::CurrentSettings.password_authentication_enabled_for_git? && !ldap_user?
  end

  def can_change_username?
    gitlab_config.username_changing_enabled
  end

  def can_create_project?
    projects_limit_left > 0
  end

  def can_create_group?
    can?(:create_group)
  end

  def can_select_namespace?
    several_namespaces? || admin
  end

  def can?(action, subject = :global)
    Ability.allowed?(self, action, subject)
  end

  def confirm_deletion_with_password?
    !password_automatically_set? && allow_password_authentication?
  end

  def first_name
    name.split.first unless name.blank?
  end

  def projects_limit_left
    projects_limit - personal_projects_count
  end

  def recent_push(project = nil)
    service = Users::LastPushEventService.new(self)

    if project
      service.last_event_for_project(project)
    else
      service.last_event_for_user
    end
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
    namespace.find_fork_of(project)
  end

  def ldap_user?
    if identities.loaded?
      identities.find { |identity| Gitlab::Auth::OAuth::Provider.ldap_provider?(identity.provider) && !identity.extern_uid.nil? }
    else
      identities.exists?(["provider LIKE ? AND extern_uid IS NOT NULL", "ldap%"])
    end
  end

  def ldap_identity
    @ldap_identity ||= identities.find_by(["provider LIKE ?", "ldap%"])
  end

  def project_deploy_keys
    DeployKey.unscoped.in_projects(authorized_projects.pluck(:id)).distinct(:id)
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
    %i[skype linkedin twitter].each do |attr|
      value = self[attr]
      self[attr] = Sanitize.clean(value) if value.present?
    end
  end

  def set_notification_email
    if notification_email.blank? || !all_emails.include?(notification_email)
      self.notification_email = email
    end
  end

  def set_public_email
    if public_email.blank? || !all_emails.include?(public_email)
      self.public_email = ''
    end
  end

  def update_secondary_emails!
    set_notification_email
    set_public_email
    save if notification_email_changed? || public_email_changed?
  end

  def set_projects_limit
    # `User.select(:id)` raises
    # `ActiveModel::MissingAttributeError: missing attribute: projects_limit`
    # without this safeguard!
    return unless has_attribute?(:projects_limit) && projects_limit.nil?

    self.projects_limit = Gitlab::CurrentSettings.default_projects_limit
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
      public_send("#{k}=", v) # rubocop:disable GitlabSecurity/PublicSend
    end

    self
  end

  def can_leave_project?(project)
    project.namespace != namespace &&
      project.project_member(self)
  end

  def full_website_url
    return "http://#{website_url}" if website_url !~ %r{\Ahttps?://}

    website_url
  end

  def short_website_url
    website_url.sub(%r{\Ahttps?://}, '')
  end

  def all_ssh_keys
    keys.map(&:publishable_key)
  end

  def temp_oauth_email?
    email.start_with?('temp-email-for-oauth')
  end

  def avatar_url(size: nil, scale: 2, **args)
    GravatarService.new.execute(email, size, scale, username: username)
  end

  def primary_email_verified?
    confirmed? && !temp_oauth_email?
  end

  def all_emails
    all_emails = []
    all_emails << email unless temp_oauth_email?
    all_emails.concat(emails.map(&:email))
    all_emails
  end

  def verified_emails
    verified_emails = []
    verified_emails << email if primary_email_verified?
    verified_emails.concat(emails.confirmed.pluck(:email))
    verified_emails
  end

  def verified_email?(check_email)
    downcased = check_email.downcase
    email == downcased ? primary_email_verified? : emails.confirmed.where(email: downcased).exists?
  end

  def hook_attrs
    {
      name: name,
      username: username,
      avatar_url: avatar_url(only_path: false)
    }
  end

  def ensure_namespace_correct
    if namespace
      namespace.path = namespace.name = username if username_changed?
    else
      build_namespace(path: username, name: username)
    end
  end

  def set_username_errors
    namespace_path_errors = self.errors.delete(:"namespace.path")
    self.errors[:username].concat(namespace_path_errors) if namespace_path_errors
  end

  def username_changed_hook
    system_hook_service.execute_hooks_for(self, :rename)
  end

  def post_destroy_hook
    log_info("User \"#{name}\" (#{email})  was removed")

    system_hook_service.execute_hooks_for(self, :destroy)
  end

  def remove_key_cache
    Users::KeysCountService.new(self).delete_cache
  end

  def delete_async(deleted_by:, params: {})
    block if params[:hard_delete]
    DeleteUserWorker.perform_async(deleted_by.id, id, params)
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
      user_star_project = users_star_projects
          .where(project: project, user: self).lock(true).first

      if user_star_project
        user_star_project.destroy
      else
        UsersStarProject.create!(project: project, user: self)
      end
    end
  end

  def manageable_namespaces
    @manageable_namespaces ||= [namespace] + manageable_groups
  end

  def manageable_groups
    union_sql = Gitlab::SQL::Union.new([owned_groups.select(:id), masters_groups.select(:id)]).to_sql

    # Update this line to not use raw SQL when migrated to Rails 5.2.
    # Either ActiveRecord or Arel constructions are fine.
    # This was replaced with the raw SQL construction because of bugs in the arel gem.
    # Bugs were fixed in arel 9.0.0 (Rails 5.2).
    owned_and_master_groups = Group.where("namespaces.id IN (#{union_sql})") # rubocop:disable GitlabSecurity/SqlInjection

    Gitlab::GroupHierarchy.new(owned_and_master_groups).base_and_descendants
  end

  def namespaces
    namespace_ids = groups.pluck(:id)
    namespace_ids.push(namespace.id)
    Namespace.where(id: namespace_ids)
  end

  def oauth_authorized_tokens
    Doorkeeper::AccessToken.where(resource_owner_id: id, revoked_at: nil)
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
    events = Event.select(:project_id)
      .contributions.where(author_id: self)
      .where("created_at > ?", Time.now - 1.year)
      .uniq
      .reorder(nil)

    Project.where(id: events)
  end

  def can_be_removed?
    !solo_owned_groups.present?
  end

  def ci_authorized_runners
    @ci_authorized_runners ||= begin
      runner_ids = Ci::RunnerProject
        .where(project: authorized_projects(Gitlab::Access::MASTER))
        .select(:runner_id)
      Ci::Runner.specific.where(id: runner_ids)
    end
  end

  def notification_settings_for(source)
    if notification_settings.loaded?
      notification_settings.find { |notification| notification.source == source }
    else
      notification_settings.find_or_initialize_by(source: source)
    end
  end

  # Lazy load global notification setting
  # Initializes User setting with Participating level if setting not persisted
  def global_notification_setting
    return @global_notification_setting if defined?(@global_notification_setting)

    @global_notification_setting = notification_settings.find_or_initialize_by(source: nil)
    @global_notification_setting.update_attributes(level: NotificationSetting.levels[DEFAULT_NOTIFICATION_LEVEL]) unless @global_notification_setting.persisted?

    @global_notification_setting
  end

  def assigned_open_merge_requests_count(force: false)
    Rails.cache.fetch(['users', id, 'assigned_open_merge_requests_count'], force: force, expires_in: 20.minutes) do
      MergeRequestsFinder.new(self, assignee_id: self.id, state: 'opened').execute.count
    end
  end

  def assigned_open_issues_count(force: false)
    Rails.cache.fetch(['users', id, 'assigned_open_issues_count'], force: force, expires_in: 20.minutes) do
      IssuesFinder.new(self, assignee_id: self.id, state: 'opened').execute.count
    end
  end

  def todos_done_count(force: false)
    Rails.cache.fetch(['users', id, 'todos_done_count'], force: force, expires_in: 20.minutes) do
      TodosFinder.new(self, state: :done).execute.count
    end
  end

  def todos_pending_count(force: false)
    Rails.cache.fetch(['users', id, 'todos_pending_count'], force: force, expires_in: 20.minutes) do
      TodosFinder.new(self, state: :pending).execute.count
    end
  end

  def personal_projects_count(force: false)
    Rails.cache.fetch(['users', id, 'personal_projects_count'], force: force, expires_in: 24.hours, raw: true) do
      personal_projects.count
    end.to_i
  end

  def update_todos_count_cache
    todos_done_count(force: true)
    todos_pending_count(force: true)
  end

  def invalidate_cache_counts
    invalidate_issue_cache_counts
    invalidate_merge_request_cache_counts
    invalidate_todos_done_count
    invalidate_todos_pending_count
    invalidate_personal_projects_count
  end

  def invalidate_issue_cache_counts
    Rails.cache.delete(['users', id, 'assigned_open_issues_count'])
  end

  def invalidate_merge_request_cache_counts
    Rails.cache.delete(['users', id, 'assigned_open_merge_requests_count'])
  end

  def invalidate_todos_done_count
    Rails.cache.delete(['users', id, 'todos_done_count'])
  end

  def invalidate_todos_pending_count
    Rails.cache.delete(['users', id, 'todos_pending_count'])
  end

  def invalidate_personal_projects_count
    Rails.cache.delete(['users', id, 'personal_projects_count'])
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
      Users::UpdateService.new(self, user: self).execute(validate: false)
    end
  end

  def access_level
    if admin?
      :admin
    else
      :regular
    end
  end

  def access_level=(new_level)
    new_level = new_level.to_s
    return unless %w(admin regular).include?(new_level)

    self.admin = (new_level == 'admin')
  end

  # Does the user have access to all private groups & projects?
  # Overridden in EE to also check auditor?
  def full_private_access?
    admin?
  end

  def update_two_factor_requirement
    periods = expanded_groups_requiring_two_factor_authentication.pluck(:two_factor_grace_period)

    self.require_two_factor_authentication_from_group = periods.any?
    self.two_factor_grace_period = periods.min || User.column_defaults['two_factor_grace_period']

    save
  end

  # each existing user needs to have an `rss_token`.
  # we do this on read since migrating all existing users is not a feasible
  # solution.
  def rss_token
    ensure_rss_token!
  end

  def sync_attribute?(attribute)
    return true if ldap_user? && attribute == :email

    attributes = Gitlab.config.omniauth.sync_profile_attributes

    if attributes.is_a?(Array)
      attributes.include?(attribute.to_s)
    else
      attributes
    end
  end

  def read_only_attribute?(attribute)
    user_synced_attributes_metadata&.read_only?(attribute)
  end

  # override, from Devise
  def lock_access!
    Gitlab::AppLogger.info("Account Locked: username=#{username}")
    super
  end

  # Determine the maximum access level for a group of projects in bulk.
  #
  # Returns a Hash mapping project ID -> maximum access level.
  def max_member_access_for_project_ids(project_ids)
    max_member_access_for_resource_ids(Project, project_ids) do |project_ids|
      project_authorizations.where(project: project_ids)
                            .group(:project_id)
                            .maximum(:access_level)
    end
  end

  def max_member_access_for_project(project_id)
    max_member_access_for_project_ids([project_id])[project_id]
  end

  # Determine the maximum access level for a group of groups in bulk.
  #
  # Returns a Hash mapping project ID -> maximum access level.
  def max_member_access_for_group_ids(group_ids)
    max_member_access_for_resource_ids(Group, group_ids) do |group_ids|
      group_members.where(source: group_ids).group(:source_id).maximum(:access_level)
    end
  end

  def max_member_access_for_group(group_id)
    max_member_access_for_group_ids([group_id])[group_id]
  end

  protected

  # override, from Devise::Validatable
  def password_required?
    return false if internal?

    super
  end

  private

  def owned_projects_union
    Gitlab::SQL::Union.new([
      Project.where(namespace: namespace),
      Project.joins(:project_authorizations)
        .where("projects.namespace_id <> ?", namespace.id)
        .where(project_authorizations: { user_id: id, access_level: Gitlab::Access::OWNER })
    ], remove_duplicates: false)
  end

  # Added according to https://github.com/plataformatec/devise/blob/7df57d5081f9884849ca15e4fde179ef164a575f/README.md#activejob-integration
  def send_devise_notification(notification, *args)
    return true unless can?(:receive_notifications)

    devise_mailer.__send__(notification, self, *args).deliver_later # rubocop:disable GitlabSecurity/PublicSend
  end

  # This works around a bug in Devise 4.2.0 that erroneously causes a user to
  # be considered active in MySQL specs due to a sub-second comparison
  # issue. For more details, see: https://gitlab.com/gitlab-org/gitlab-ee/issues/2362#note_29004709
  def confirmation_period_valid?
    return false if self.class.allow_unconfirmed_access_for == 0.days

    super
  end

  def ensure_user_rights_and_limits
    if external?
      self.can_create_group = false
      self.projects_limit   = 0
    else
      # Only revert these back to the default if they weren't specifically changed in this update.
      self.can_create_group = gitlab_config.default_can_create_group unless can_create_group_changed?
      self.projects_limit = Gitlab::CurrentSettings.default_projects_limit unless projects_limit_changed?
    end
  end

  def signup_domain_valid?
    valid = true
    error = nil

    if Gitlab::CurrentSettings.domain_blacklist_enabled?
      blocked_domains = Gitlab::CurrentSettings.domain_blacklist
      if domain_matches?(blocked_domains, email)
        error = 'is not from an allowed domain.'
        valid = false
      end
    end

    allowed_domains = Gitlab::CurrentSettings.domain_whitelist
    unless allowed_domains.blank?
      if domain_matches?(allowed_domains, email)
        valid = true
      else
        error = "domain is not authorized for sign-up"
        valid = false
      end
    end

    errors.add(:email, error) unless valid

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

  def self.unique_internal(scope, username, email_pattern, &b)
    scope.first || create_unique_internal(scope, username, email_pattern, &b)
  end

  def self.create_unique_internal(scope, username, email_pattern, &creation_block)
    # Since we only want a single one of these in an instance, we use an
    # exclusive lease to ensure than this block is never run concurrently.
    lease_key = "user:unique_internal:#{username}"
    lease = Gitlab::ExclusiveLease.new(lease_key, timeout: 1.minute.to_i)

    until uuid = lease.try_obtain
      # Keep trying until we obtain the lease. To prevent hammering Redis too
      # much we'll wait for a bit between retries.
      sleep(1)
    end

    # Recheck if the user is already present. One might have been
    # added between the time we last checked (first line of this method)
    # and the time we acquired the lock.
    existing_user = uncached { scope.first }
    return existing_user if existing_user.present?

    uniquify = Uniquify.new

    username = uniquify.string(username) { |s| User.find_by_username(s) }

    email = uniquify.string(-> (n) { Kernel.sprintf(email_pattern, n) }) do |s|
      User.find_by_email(s)
    end

    user = scope.build(
      username: username,
      email: email,
      &creation_block
    )

    Users::UpdateService.new(user, user: user).execute(validate: false)
    user
  ensure
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end
end
