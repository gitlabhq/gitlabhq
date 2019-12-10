# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class User < ApplicationRecord
  extend Gitlab::ConfigHelper

  include Gitlab::ConfigHelper
  include Gitlab::SQL::Pattern
  include AfterCommitQueue
  include Avatarable
  include Referable
  include Sortable
  include CaseSensitivity
  include TokenAuthenticatable
  include FeatureGate
  include CreatedAtFilterable
  include BulkMemberAccessLoad
  include BlocksJsonSerialization
  include WithUploads
  include OptionallySearch
  include FromUnion

  DEFAULT_NOTIFICATION_LEVEL = :participating

  add_authentication_token_field :incoming_email_token, token_generator: -> { SecureRandom.hex.to_i(16).to_s(36) }
  add_authentication_token_field :feed_token
  add_authentication_token_field :static_object_token

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
                    "administrator if you think this is an error."

  MINIMUM_INACTIVE_DAYS = 180

  # Override Devise::Models::Trackable#update_tracked_fields!
  # to limit database writes to at most once every hour
  # rubocop: disable CodeReuse/ServiceClass
  def update_tracked_fields!(request)
    return if Gitlab::Database.read_only?

    update_tracked_fields(request)

    lease = Gitlab::ExclusiveLease.new("user_update_tracked_fields:#{id}", timeout: 1.hour.to_i)
    return unless lease.try_obtain

    Users::UpdateService.new(self, user: self).execute(validate: false)
  end
  # rubocop: enable CodeReuse/ServiceClass

  attr_accessor :force_random_password

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace, -> { where(type: nil) }, dependent: :destroy, foreign_key: :owner_id, inverse_of: :owner, autosave: true # rubocop:disable Cop/ActiveRecordDependent

  # Profile
  has_many :keys, -> { regular_keys }, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :deploy_keys, -> { where(type: 'DeployKey') }, dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
  has_many :gpg_keys

  has_many :emails, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :personal_access_tokens, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :identities, dependent: :destroy, autosave: true # rubocop:disable Cop/ActiveRecordDependent
  has_many :u2f_registrations, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :chat_names, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one :user_synced_attributes_metadata, autosave: true
  has_one :aws_role, class_name: 'Aws::Role'

  # Groups
  has_many :members
  has_many :group_members, -> { where(requested_at: nil) }, source: 'GroupMember'
  has_many :groups, through: :group_members
  has_many :owned_groups, -> { where(members: { access_level: Gitlab::Access::OWNER }) }, through: :group_members, source: :group
  has_many :maintainers_groups, -> { where(members: { access_level: Gitlab::Access::MAINTAINER }) }, through: :group_members, source: :group
  has_many :developer_groups, -> { where(members: { access_level: ::Gitlab::Access::DEVELOPER }) }, through: :group_members, source: :group
  has_many :owned_or_maintainers_groups,
           -> { where(members: { access_level: [Gitlab::Access::MAINTAINER, Gitlab::Access::OWNER] }) },
           through: :group_members,
           source: :group
  alias_attribute :masters_groups, :maintainers_groups

  # Projects
  has_many :groups_projects,          through: :groups, source: :projects
  has_many :personal_projects,        through: :namespace, source: :projects
  has_many :project_members, -> { where(requested_at: nil) }
  has_many :projects,                 through: :project_members
  has_many :created_projects,         foreign_key: :creator_id, class_name: 'Project'
  has_many :users_star_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :starred_projects, through: :users_star_projects, source: :project
  has_many :project_authorizations, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :authorized_projects, through: :project_authorizations, source: :project

  has_many :user_interacted_projects
  has_many :project_interactions, through: :user_interacted_projects, source: :project, class_name: 'Project'

  has_many :snippets,                 dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :issues,                   dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :events,                   dependent: :delete_all, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :releases,                 dependent: :nullify, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :subscriptions,            dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one  :abuse_report,             dependent: :destroy, foreign_key: :user_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :reported_abuse_reports,   dependent: :destroy, foreign_key: :reporter_id, class_name: "AbuseReport" # rubocop:disable Cop/ActiveRecordDependent
  has_many :spam_logs,                dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :builds,                   dependent: :nullify, class_name: 'Ci::Build' # rubocop:disable Cop/ActiveRecordDependent
  has_many :pipelines,                dependent: :nullify, class_name: 'Ci::Pipeline' # rubocop:disable Cop/ActiveRecordDependent
  has_many :todos
  has_many :notification_settings
  has_many :award_emoji,              dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :triggers,                 dependent: :destroy, class_name: 'Ci::Trigger', foreign_key: :owner_id # rubocop:disable Cop/ActiveRecordDependent

  has_many :issue_assignees
  has_many :assigned_issues, class_name: "Issue", through: :issue_assignees, source: :issue
  has_many :assigned_merge_requests, dependent: :nullify, foreign_key: :assignee_id, class_name: "MergeRequest" # rubocop:disable Cop/ActiveRecordDependent

  has_many :custom_attributes, class_name: 'UserCustomAttribute'
  has_many :callouts, class_name: 'UserCallout'
  has_many :term_agreements
  belongs_to :accepted_term, class_name: 'ApplicationSetting::Term'

  has_one :status, class_name: 'UserStatus'
  has_one :user_preference

  #
  # Validations
  #
  # Note: devise :validatable above adds validations for :email and :password
  validates :name, presence: true, length: { maximum: 128 }
  validates :first_name, length: { maximum: 255 }
  validates :last_name, length: { maximum: 255 }
  validates :email, confirmation: true
  validates :notification_email, presence: true
  validates :notification_email, devise_email: true, if: ->(user) { user.notification_email != user.email }
  validates :public_email, presence: true, uniqueness: true, devise_email: true, allow_blank: true
  validates :commit_email, devise_email: true, allow_nil: true, if: ->(user) { user.commit_email != user.email }
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
  validate :owns_commit_email, if: :commit_email_changed?
  validate :signup_domain_valid?, on: :create, if: ->(user) { !user.created_by_id }

  before_validation :sanitize_attrs
  before_validation :set_notification_email, if: :new_record?
  before_validation :set_public_email, if: :public_email_changed?
  before_validation :set_commit_email, if: :commit_email_changed?
  before_save :default_private_profile_to_false
  before_save :set_public_email, if: :public_email_changed? # in case validation is skipped
  before_save :set_commit_email, if: :commit_email_changed? # in case validation is skipped
  before_save :ensure_incoming_email_token
  before_save :ensure_user_rights_and_limits, if: ->(user) { user.new_record? || user.external_changed? }
  before_save :skip_reconfirmation!, if: ->(user) { user.email_changed? && user.read_only_attribute?(:email) }
  before_save :check_for_verified_email, if: ->(user) { user.email_changed? && !user.new_record? }
  before_validation :ensure_namespace_correct
  before_save :ensure_namespace_correct # in case validation is skipped
  after_validation :set_username_errors
  after_update :username_changed_hook, if: :saved_change_to_username?
  after_destroy :post_destroy_hook
  after_destroy :remove_key_cache
  after_commit(on: :update) do
    if previous_changes.key?('email')
      # Grab previous_email here since previous_changes changes after
      # #update_emails_with_primary_email and #update_notification_email are called
      previous_email = previous_changes[:email][0]

      update_emails_with_primary_email(previous_email)
      update_invalid_gpg_signatures

      if previous_email == notification_email
        self.notification_email = email
        save
      end
    end
  end

  after_initialize :set_projects_limit

  # User's Layout preference
  enum layout: [:fixed, :fluid]

  # User's Dashboard preference
  # Note: When adding an option, it MUST go on the end of the array.
  enum dashboard: [:projects, :stars, :project_activity, :starred_project_activity, :groups, :todos, :issues, :merge_requests, :operations]

  # User's Project preference
  # Note: When adding an option, it MUST go on the end of the array.
  enum project_view: [:readme, :activity, :files]

  # User's role
  # Note: When adding an option, it MUST go on the end of the array.
  enum role: [:software_developer, :development_team_lead, :devops_engineer, :systems_administrator, :security_analyst, :data_analyst, :product_manager, :product_designer, :other], _suffix: true

  delegate :path, to: :namespace, allow_nil: true, prefix: true
  delegate :notes_filter_for, to: :user_preference
  delegate :set_notes_filter, to: :user_preference
  delegate :first_day_of_week, :first_day_of_week=, to: :user_preference
  delegate :timezone, :timezone=, to: :user_preference
  delegate :time_display_relative, :time_display_relative=, to: :user_preference
  delegate :time_format_in_24h, :time_format_in_24h=, to: :user_preference
  delegate :show_whitespace_in_diffs, :show_whitespace_in_diffs=, to: :user_preference
  delegate :sourcegraph_enabled, :sourcegraph_enabled=, to: :user_preference
  delegate :setup_for_company, :setup_for_company=, to: :user_preference

  accepts_nested_attributes_for :user_preference, update_only: true

  state_machine :state, initial: :active do
    event :block do
      transition active: :blocked
      transition deactivated: :blocked
      transition ldap_blocked: :blocked
    end

    event :ldap_block do
      transition active: :ldap_blocked
      transition deactivated: :ldap_blocked
    end

    event :activate do
      transition deactivated: :active
      transition blocked: :active
      transition ldap_blocked: :active
    end

    event :deactivate do
      transition active: :deactivated
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

    # rubocop: disable CodeReuse/ServiceClass
    # Ideally we should not call a service object here but user.block
    # is also bcalled by Users::MigrateToGhostUserService which references
    # this state transition object in order to do a rollback.
    # For this reason the tradeoff is to disable this cop.
    after_transition any => :blocked do |user|
      Ci::CancelUserPipelinesService.new.execute(user)
    end
    # rubocop: enable CodeReuse/ServiceClass
  end

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :blocked, -> { with_states(:blocked, :ldap_blocked) }
  scope :external, -> { where(external: true) }
  scope :active, -> { with_state(:active).non_internal }
  scope :deactivated, -> { with_state(:deactivated).non_internal }
  scope :without_projects, -> { joins('LEFT JOIN project_authorizations ON users.id = project_authorizations.user_id').where(project_authorizations: { user_id: nil }) }
  scope :order_recent_sign_in, -> { reorder(Gitlab::Database.nulls_last_order('current_sign_in_at', 'DESC')) }
  scope :order_oldest_sign_in, -> { reorder(Gitlab::Database.nulls_last_order('current_sign_in_at', 'ASC')) }
  scope :order_recent_last_activity, -> { reorder(Gitlab::Database.nulls_last_order('last_activity_on', 'DESC')) }
  scope :order_oldest_last_activity, -> { reorder(Gitlab::Database.nulls_first_order('last_activity_on', 'ASC')) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :by_username, -> (usernames) { iwhere(username: Array(usernames).map(&:to_s)) }
  scope :for_todos, -> (todos) { where(id: todos.select(:user_id)) }
  scope :with_emails, -> { preload(:emails) }
  scope :with_dashboard, -> (dashboard) { where(dashboard: dashboard) }
  scope :with_public_profile, -> { where(private_profile: false) }

  scope :with_expiring_and_not_notified_personal_access_tokens, ->(at) do
    where('EXISTS (?)',
          ::PersonalAccessToken
            .where('personal_access_tokens.user_id = users.id')
            .expiring_and_not_notified(at).select(1))
  end

  def self.with_visible_profile(user)
    return with_public_profile if user.nil?

    if user.admin?
      all
    else
      with_public_profile.or(where(id: user.id))
    end
  end

  # Limits the users to those that have TODOs, optionally in the given state.
  #
  # user - The user to get the todos for.
  #
  # with_todos - If we should limit the result set to users that are the
  #              authors of todos.
  #
  # todo_state - An optional state to require the todos to be in.
  def self.limit_to_todo_authors(user: nil, with_todos: false, todo_state: nil)
    if user && with_todos
      where(id: Todo.where(user: user, state: todo_state).select(:author_id))
    else
      all
    end
  end

  # Returns a relation that optionally includes the given user.
  #
  # user_id - The ID of the user to include.
  def self.union_with_user(user_id = nil)
    if user_id.present?
      # We use "unscoped" here so that any inner conditions are not repeated for
      # the outer query, which would be redundant.
      User.unscoped.from_union([all, User.unscoped.where(id: user_id)])
    else
      all
    end
  end

  def self.with_two_factor
    with_u2f_registrations = <<-SQL
      EXISTS (
        SELECT *
        FROM u2f_registrations AS u2f
        WHERE u2f.user_id = users.id
      ) OR users.otp_required_for_login = ?
    SQL

    where(with_u2f_registrations, true)
  end

  def self.without_two_factor
    joins("LEFT OUTER JOIN u2f_registrations AS u2f ON u2f.user_id = users.id")
      .where("u2f.id IS NULL AND users.otp_required_for_login = ?", false)
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
      when 'last_activity_on_desc' then order_recent_last_activity
      when 'last_activity_on_asc' then order_oldest_last_activity
      else
        order_by(order_method)
      end
    end

    def for_github_id(id)
      joins(:identities).merge(Identity.with_extern_uid(:github, id))
    end

    # Find a User by their primary email or any associated secondary email
    def find_by_any_email(email, confirmed: false)
      return unless email

      by_any_email(email, confirmed: confirmed).take
    end

    # Returns a relation containing all the users for the given email addresses
    #
    # @param emails [String, Array<String>] email addresses to check
    # @param confirmed [Boolean] Only return users where the email is confirmed
    def by_any_email(emails, confirmed: false)
      emails = Array(emails).map(&:downcase)

      from_users = where(email: emails)
      from_users = from_users.confirmed if confirmed

      from_emails = joins(:emails).where(emails: { email: emails })
      from_emails = from_emails.confirmed.merge(Email.confirmed) if confirmed

      items = [from_users, from_emails]

      user_ids = Gitlab::PrivateCommitEmail.user_ids_for_emails(emails)
      items << where(id: user_ids) if user_ids.present?

      from_union(items)
    end

    def find_by_private_commit_email(email)
      user_id = Gitlab::PrivateCommitEmail.user_id_for_email(email)

      find_by(id: user_id)
    end

    def filter_items(filter_name)
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
      when 'deactivated'
        deactivated
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
      query = query&.delete_prefix('@')
      return none if query.blank?

      query = query.downcase

      order = <<~SQL
        CASE
          WHEN users.name = :query THEN 0
          WHEN users.username = :query THEN 1
          WHEN users.email = :query THEN 2
          ELSE 3
        END
      SQL

      sanitized_order_sql = Arel.sql(sanitize_sql_array([order, query: query]))

      where(
        fuzzy_arel_match(:name, query, lower_exact_match: true)
          .or(fuzzy_arel_match(:username, query, lower_exact_match: true))
          .or(arel_table[:email].eq(query))
      ).reorder(sanitized_order_sql, :name)
    end

    # Limits the result set to users _not_ in the given query/list of IDs.
    #
    # users - The list of users to ignore. This can be an
    #         `ActiveRecord::Relation`, or an Array.
    def where_not_in(users = nil)
      users ? where.not(id: users) : all
    end

    def reorder_by_name
      reorder(:name)
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
      return unless login

      if login.include?('@')
        unscoped.iwhere(email: login).take
      else
        unscoped.iwhere(username: login).take
      end
    end

    def find_by_username(username)
      by_username(username).take
    end

    def find_by_username!(username)
      by_username(username).take!
    end

    # Returns a user for the given SSH key.
    def find_by_ssh_key_id(key_id)
      find_by('EXISTS (?)', Key.select(1).where('keys.user_id = users.id').where(id: key_id))
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
        u.bio = _('This is a "Ghost User", created to hold all issues authored by users that have since been deleted. This user cannot be removed.')
        u.name = 'Ghost User'
      end
    end

    # Return true if there is only single non-internal user in the deployment,
    # ghost user is ignored.
    def single_user?
      User.non_internal.limit(2).count == 1
    end

    def single_user
      User.non_internal.first if single_user?
    end
  end

  def full_path
    username
  end

  def internal?
    ghost?
  end

  def self.internal
    where(ghost: true)
  end

  def self.non_internal
    where('ghost IS NOT TRUE')
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
      update(
        otp_required_for_login:      false,
        encrypted_otp_secret:        nil,
        encrypted_otp_secret_iv:     nil,
        encrypted_otp_secret_salt:   nil,
        otp_grace_period_started_at: nil,
        otp_backup_codes:            nil
      )
      self.u2f_registrations.destroy_all # rubocop: disable DestroyAll
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
      errors.add(:username, _('cannot be changed if a personal project has container registry tags.'))
    end
  end

  # will_save_change_to_attribute? is used by Devise to check if it is necessary
  # to clear any existing reset_password_tokens before updating an authentication_key
  # and login in our case is a virtual attribute to allow login by username or email.
  def will_save_change_to_login?
    will_save_change_to_username? || will_save_change_to_email?
  end

  def unique_email
    if !emails.exists?(email: email) && Email.exists?(email: email)
      errors.add(:email, _('has already been taken'))
    end
  end

  def owns_notification_email
    return if temp_oauth_email?

    errors.add(:notification_email, _("is not an email you own")) unless all_emails.include?(notification_email)
  end

  def owns_public_email
    return if public_email.blank?

    errors.add(:public_email, _("is not an email you own")) unless all_emails.include?(public_email)
  end

  def owns_commit_email
    return if read_attribute(:commit_email).blank?

    errors.add(:commit_email, _("is not an email you own")) unless verified_emails.include?(commit_email)
  end

  # Define commit_email-related attribute methods explicitly instead of relying
  # on ActiveRecord to provide them. Some of the specs use the current state of
  # the model code but an older database schema, so we need to guard against the
  # possibility of the commit_email column not existing.

  def commit_email
    return self.email unless has_attribute?(:commit_email)

    if super == Gitlab::PrivateCommitEmail::TOKEN
      return private_commit_email
    end

    # The commit email is the same as the primary email if undefined
    super.presence || self.email
  end

  def commit_email=(email)
    super if has_attribute?(:commit_email)
  end

  def commit_email_changed?
    has_attribute?(:commit_email) && super
  end

  def private_commit_email
    Gitlab::PrivateCommitEmail.for_user(self)
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
  # rubocop: disable CodeReuse/ServiceClass
  def update_emails_with_primary_email(previous_email)
    primary_email_record = emails.find_by(email: email)
    Emails::DestroyService.new(self, user: self).execute(primary_email_record) if primary_email_record

    # the original primary email was confirmed, and we want that to carry over.  We don't
    # have access to the original confirmation values at this point, so just set confirmed_at
    Emails::CreateService.new(self, user: self, email: previous_email).execute(confirmed_at: confirmed_at)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def update_invalid_gpg_signatures
    gpg_keys.each(&:update_invalid_gpg_signatures)
  end

  # Returns the groups a user has access to, either through a membership or a project authorization
  def authorized_groups
    Group.unscoped do
      Group.from_union([
        groups,
        authorized_projects.joins(:namespace).select('namespaces.*')
      ])
    end
  end

  # Returns the groups a user is a member of, either directly or through a parent group
  def membership_groups
    Gitlab::ObjectHierarchy.new(groups).base_and_descendants
  end

  # Returns a relation of groups the user has access to, including their parent
  # and child groups (recursively).
  def all_expanded_groups
    Gitlab::ObjectHierarchy.new(groups).all_objects
  end

  def expanded_groups_requiring_two_factor_authentication
    all_expanded_groups.where(require_two_factor_authentication: true)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def refresh_authorized_projects
    Users::RefreshAuthorizedProjectsService.new(self).execute
  end
  # rubocop: enable CodeReuse/ServiceClass

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
  # The param `related_project_column` is the column to compare to the
  # project_authorizations. By default is projects.id
  #
  # Example use:
  # `Project.where('EXISTS(?)', user.authorizations_for_projects)`
  def authorizations_for_projects(min_access_level: nil, related_project_column: 'projects.id')
    authorizations = project_authorizations
                      .select(1)
                      .where("project_authorizations.project_id = #{related_project_column}")

    return authorizations unless min_access_level.present?

    authorizations.where('project_authorizations.access_level >= ?', min_access_level)
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
    @owned_projects ||= Project.from_union(
      [
        Project.where(namespace: namespace),
        Project.joins(:project_authorizations)
          .where("projects.namespace_id <> ?", namespace.id)
          .where(project_authorizations: { user_id: id, access_level: Gitlab::Access::OWNER })
      ],
      remove_duplicates: false
    )
  end

  # Returns projects which user can admin issues on (for example to move an issue to that project).
  #
  # This logic is duplicated from `Ability#project_abilities` into a SQL form.
  def projects_where_can_admin_issues
    authorized_projects(Gitlab::Access::REPORTER).non_archived.with_issues_enabled
  end

  # rubocop: disable CodeReuse/ServiceClass
  def require_ssh_key?
    count = Users::KeysCountService.new(self).count

    count.zero? && Gitlab::ProtocolAccess.allowed?('ssh')
  end
  # rubocop: enable CodeReuse/ServiceClass

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
    Gitlab::CurrentSettings.password_authentication_enabled_for_web? && !ldap_user? && !ultraauth_user?
  end

  def allow_password_authentication_for_git?
    Gitlab::CurrentSettings.password_authentication_enabled_for_git? && !ldap_user? && !ultraauth_user?
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
    read_attribute(:first_name) || begin
      name.split(' ').first unless name.blank?
    end
  end

  def last_name
    read_attribute(:last_name) || begin
      name.split(' ').drop(1).join(' ') unless name.blank?
    end
  end

  def projects_limit_left
    projects_limit - personal_projects_count
  end

  # rubocop: disable CodeReuse/ServiceClass
  def recent_push(project = nil)
    service = Users::LastPushEventService.new(self)

    if project
      service.last_event_for_project(project)
    else
      service.last_event_for_user
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def several_namespaces?
    union_sql = ::Gitlab::SQL::Union.new(
      [owned_groups,
       maintainers_groups,
       groups_with_developer_maintainer_project_access]).to_sql

    ::Group.from("(#{union_sql}) #{::Group.table_name}").any?
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

  def ultraauth_user?
    if identities.loaded?
      identities.find { |identity| Gitlab::Auth::OAuth::Provider.ultraauth_provider?(identity.provider) && !identity.extern_uid.nil? }
    else
      identities.exists?(["provider = ? AND extern_uid IS NOT NULL", "ultraauth"])
    end
  end

  def ldap_identity
    @ldap_identity ||= identities.find_by(["provider LIKE ?", "ldap%"])
  end

  def project_deploy_keys
    DeployKey.in_projects(authorized_projects.select(:id)).distinct(:id)
  end

  def highest_role
    members.maximum(:access_level) || Gitlab::Access::NO_ACCESS
  end

  def accessible_deploy_keys
    DeployKey.from_union([
      DeployKey.where(id: project_deploy_keys.select(:deploy_key_id)),
      DeployKey.are_public
    ])
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
    if notification_email.blank? || all_emails.exclude?(notification_email)
      self.notification_email = email
    end
  end

  def set_public_email
    if public_email.blank? || all_emails.exclude?(public_email)
      self.public_email = ''
    end
  end

  def set_commit_email
    if commit_email.blank? || verified_emails.exclude?(commit_email)
      self.commit_email = nil
    end
  end

  def update_secondary_emails!
    set_notification_email
    set_public_email
    set_commit_email
    save if notification_email_changed? || public_email_changed? || commit_email_changed?
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
      !last_credential_check_at || (last_credential_check_at + ldap_sync_time) < Time.now
    else
      false
    end
  end

  def ldap_sync_time
    # This number resides in this method so it can be redefined in EE.
    1.hour
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

  # rubocop: disable CodeReuse/ServiceClass
  def avatar_url(size: nil, scale: 2, **args)
    GravatarService.new.execute(email, size, scale, username: username)
  end
  # rubocop: enable CodeReuse/ServiceClass

  def primary_email_verified?
    confirmed? && !temp_oauth_email?
  end

  def accept_pending_invitations!
    pending_invitations.select do |member|
      member.accept_invite!(self)
    end
  end

  def pending_invitations
    Member.where(invite_email: verified_emails).invite
  end

  def all_emails
    all_emails = []
    all_emails << email unless temp_oauth_email?
    all_emails << private_commit_email
    all_emails.concat(emails.map(&:email))
    all_emails
  end

  def verified_emails
    verified_emails = []
    verified_emails << email if primary_email_verified?
    verified_emails << private_commit_email
    verified_emails.concat(emails.confirmed.pluck(:email))
    verified_emails
  end

  def any_email?(check_email)
    downcased = check_email.downcase

    # handle the outdated private commit email case
    return true if persisted? &&
        id == Gitlab::PrivateCommitEmail.user_id_for_email(downcased)

    all_emails.include?(check_email.downcase)
  end

  def verified_email?(check_email)
    downcased = check_email.downcase

    # handle the outdated private commit email case
    return true if persisted? &&
        id == Gitlab::PrivateCommitEmail.user_id_for_email(downcased)

    verified_emails.include?(check_email.downcase)
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
      namespace.path = username if username_changed?
      namespace.name = name if name_changed?
    else
      build_namespace(path: username, name: name)
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

  # rubocop: disable CodeReuse/ServiceClass
  def remove_key_cache
    Users::KeysCountService.new(self).delete_cache
  end
  # rubocop: enable CodeReuse/ServiceClass

  def delete_async(deleted_by:, params: {})
    block if params[:hard_delete]
    DeleteUserWorker.perform_async(deleted_by.id, id, params.to_h)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def notification_service
    NotificationService.new
  end
  # rubocop: enable CodeReuse/ServiceClass

  def log_info(message)
    Gitlab::AppLogger.info message
  end

  # rubocop: disable CodeReuse/ServiceClass
  def system_hook_service
    SystemHooksService.new
  end
  # rubocop: enable CodeReuse/ServiceClass

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

  def manageable_groups(include_groups_with_developer_maintainer_access: false)
    owned_and_maintainer_group_hierarchy = Gitlab::ObjectHierarchy.new(owned_or_maintainers_groups).base_and_descendants

    if include_groups_with_developer_maintainer_access
      union_sql = ::Gitlab::SQL::Union.new(
        [owned_and_maintainer_group_hierarchy,
         groups_with_developer_maintainer_project_access]).to_sql

      ::Group.from("(#{union_sql}) #{::Group.table_name}")
    else
      owned_and_maintainer_group_hierarchy
    end
  end

  def manageable_groups_with_routes(include_groups_with_developer_maintainer_access: false)
    manageable_groups(include_groups_with_developer_maintainer_access: include_groups_with_developer_maintainer_access)
      .eager_load(:route)
      .order('routes.path')
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
      .distinct
      .reorder(nil)

    Project.where(id: events)
  end

  def can_be_removed?
    !solo_owned_groups.present?
  end

  def ci_owned_runners
    @ci_owned_runners ||= begin
      project_runners = Ci::RunnerProject
        .where(project: authorized_projects(Gitlab::Access::MAINTAINER))
        .joins(:runner)
        .select('ci_runners.*')

      group_runners = Ci::RunnerNamespace
        .where(namespace_id: owned_or_maintainers_groups.select(:id))
        .joins(:runner)
        .select('ci_runners.*')

      Ci::Runner.from_union([project_runners, group_runners])
    end
  end

  def notification_email_for(notification_group)
    # Return group-specific email address if present, otherwise return global notification email address
    notification_group&.notification_email_for(self) || notification_email
  end

  def notification_settings_for(source, inherit: false)
    if notification_settings.loaded?
      notification_settings.find do |notification|
        notification.source_type == source.class.base_class.name &&
          notification.source_id == source.id
      end
    else
      notification_settings.find_or_initialize_by(source: source) do |ns|
        next unless source.is_a?(Group) && inherit

        # If we're here it means we're trying to create a NotificationSetting for a group that doesn't have one.
        # Find the closest parent with a notification_setting that's not Global level, or that has an email set.
        ancestor_ns = source
                        .notification_settings(hierarchy_order: :asc)
                        .where(user: self)
                        .find_by('level != ? OR notification_email IS NOT NULL', NotificationSetting.levels[:global])
        # Use it to seed the settings
        ns.assign_attributes(ancestor_ns&.slice(*NotificationSetting.allowed_fields))
        ns.source = source
        ns.user = self
      end
    end
  end

  # Lazy load global notification setting
  # Initializes User setting with Participating level if setting not persisted
  def global_notification_setting
    return @global_notification_setting if defined?(@global_notification_setting)

    @global_notification_setting = notification_settings.find_or_initialize_by(source: nil)
    @global_notification_setting.update(level: NotificationSetting.levels[DEFAULT_NOTIFICATION_LEVEL]) unless @global_notification_setting.persisted?

    @global_notification_setting
  end

  def assigned_open_merge_requests_count(force: false)
    Rails.cache.fetch(['users', id, 'assigned_open_merge_requests_count'], force: force, expires_in: 20.minutes) do
      MergeRequestsFinder.new(self, assignee_id: self.id, state: 'opened', non_archived: true).execute.count
    end
  end

  def assigned_open_issues_count(force: false)
    Rails.cache.fetch(['users', id, 'assigned_open_issues_count'], force: force, expires_in: 20.minutes) do
      IssuesFinder.new(self, assignee_id: self.id, state: 'opened', non_archived: true).execute.count
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
  #   <https://github.com/plataformatec/devise/blob/v4.7.1/lib/devise/models/lockable.rb#L104>
  #
  # rubocop: disable CodeReuse/ServiceClass
  def increment_failed_attempts!
    return if ::Gitlab::Database.read_only?

    increment_failed_attempts

    if attempts_exceeded?
      lock_access! unless access_locked?
    else
      Users::UpdateService.new(self, user: self).execute(validate: false)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

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
    can?(:read_all_resources)
  end

  def update_two_factor_requirement
    periods = expanded_groups_requiring_two_factor_authentication.pluck(:two_factor_grace_period)

    self.require_two_factor_authentication_from_group = periods.any?
    self.two_factor_grace_period = periods.min || User.column_defaults['two_factor_grace_period']

    save
  end

  # each existing user needs to have an `feed_token`.
  # we do this on read since migrating all existing users is not a feasible
  # solution.
  def feed_token
    ensure_feed_token!
  end

  # Each existing user needs to have a `static_object_token`.
  # We do this on read since migrating all existing users is not a feasible
  # solution.
  def static_object_token
    ensure_static_object_token!
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

  def terms_accepted?
    accepted_term_id.present?
  end

  def required_terms_not_accepted?
    Gitlab::CurrentSettings.current_application_settings.enforce_terms? &&
      !terms_accepted?
  end

  def requires_usage_stats_consent?
    self.admin? && 7.days.ago > self.created_at && !has_current_license? && User.single_user? && !consented_usage_stats?
  end

  # Avoid migrations only building user preference object when needed.
  def user_preference
    super.presence || build_user_preference
  end

  def todos_limited_to(ids)
    todos.where(id: ids)
  end

  def pending_todo_for(target)
    todos.find_by(target: target, state: :pending)
  end

  def password_expired?
    !!(password_expires_at && password_expires_at < Time.now)
  end

  def can_be_deactivated?
    active? && no_recent_activity?
  end

  def last_active_at
    last_activity = last_activity_on&.to_time&.in_time_zone
    last_sign_in = current_sign_in_at

    [last_activity, last_sign_in].compact.max
  end

  # Below is used for the signup_flow experiment. Should be removed
  # when experiment finishes.
  # See https://gitlab.com/gitlab-org/growth/engineering/issues/64
  REQUIRES_ROLE_VALUE = 99

  def role_required?
    role_before_type_cast == REQUIRES_ROLE_VALUE
  end

  def set_role_required!
    update_column(:role, REQUIRES_ROLE_VALUE)
  end
  # End of signup_flow experiment methods

  # @deprecated
  alias_method :owned_or_masters_groups, :owned_or_maintainers_groups

  protected

  # override, from Devise::Validatable
  def password_required?
    return false if internal?

    super
  end

  # override from Devise::Confirmable
  def confirmation_period_valid?
    return false if Feature.disabled?(:soft_email_confirmation)

    super
  end

  private

  def default_private_profile_to_false
    return unless private_profile_changed? && private_profile.nil?

    self.private_profile = false
  end

  def has_current_license?
    false
  end

  def consented_usage_stats?
    # Bypass the cache here because it's possible the admin enabled the
    # usage ping, and we don't want to annoy the user again if they
    # already set the value. This is a bit of hack, but the alternative
    # would be to put in a more complex cache invalidation step. Since
    # this call only gets called in the uncommon situation where the
    # user is an admin and the only user in the instance, this shouldn't
    # cause too much load on the system.
    ApplicationSetting.current_without_cache&.usage_stats_set_by_user_id == self.id
  end

  # Added according to https://github.com/plataformatec/devise/blob/7df57d5081f9884849ca15e4fde179ef164a575f/README.md#activejob-integration
  def send_devise_notification(notification, *args)
    return true unless can?(:receive_notifications)

    devise_mailer.__send__(notification, self, *args).deliver_later # rubocop:disable GitlabSecurity/PublicSend
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

  def self.unique_internal(scope, username, email_pattern, &block)
    scope.first || create_unique_internal(scope, username, email_pattern, &block)
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

    Users::UpdateService.new(user, user: user).execute(validate: false) # rubocop: disable CodeReuse/ServiceClass
    user
  ensure
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end

  def groups_with_developer_maintainer_project_access
    project_creation_levels = [::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS]

    if ::Gitlab::CurrentSettings.default_project_creation == ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS
      project_creation_levels << nil
    end

    developer_groups_hierarchy = ::Gitlab::ObjectHierarchy.new(developer_groups).base_and_descendants
    ::Group.where(id: developer_groups_hierarchy.select(:id),
                  project_creation_level: project_creation_levels)
  end

  def no_recent_activity?
    last_active_at.to_i <= MINIMUM_INACTIVE_DAYS.days.ago.to_i
  end
end

User.prepend_if_ee('EE::User')
