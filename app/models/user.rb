require 'carrierwave/orm/activerecord'

class User < ActiveRecord::Base
  extend Gitlab::ConfigHelper

  include Gitlab::ConfigHelper
  include Gitlab::CurrentSettings
  include Avatarable
  include Referable
  include Sortable
  include CaseSensitivity
  include TokenAuthenticatable
  include IgnorableColumn
  include FeatureGate
  include CreatedAtFilterable

  prepend EE::GeoAwareAvatar
  prepend EE::User

  DEFAULT_NOTIFICATION_LEVEL = :participating

  ignore_column :authorized_projects_populated

  add_authentication_token_field :authentication_token
  add_authentication_token_field :incoming_email_token
  add_authentication_token_field :rss_token

  default_value_for :admin, false
  default_value_for(:external) { current_application_settings.user_default_external }
  default_value_for :can_create_group, gitlab_config.default_can_create_group
  default_value_for :can_create_team, false
  default_value_for :hide_no_ssh_key, false
  default_value_for :hide_no_password, false
  default_value_for :project_view, :files
  default_value_for :notified_of_own_activity, false
  default_value_for :preferred_language, I18n.default_locale

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

  # Override Devise::Models::Trackable#update_tracked_fields!
  # to limit database writes to at most once every hour
  def update_tracked_fields!(request)
    update_tracked_fields(request)

    lease = Gitlab::ExclusiveLease.new("user_update_tracked_fields:#{id}", timeout: 1.hour.to_i)
    return unless lease.try_obtain

    Users::UpdateService.new(self).execute(validate: false)
  end

  attr_accessor :force_random_password

  # Virtual attribute for authenticating by either username or email
  attr_accessor :login

  #
  # Relations
  #

  # Namespace for personal projects
  has_one :namespace, -> { where type: nil }, dependent: :destroy, foreign_key: :owner_id, autosave: true # rubocop:disable Cop/ActiveRecordDependent

  # Profile
  has_many :keys, -> do
    type = Key.arel_table[:type]
    where(type.not_eq('DeployKey').or(type.eq(nil)))
  end, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :deploy_keys, -> { where(type: 'DeployKey') }, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  has_many :emails, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :personal_access_tokens, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :identities, dependent: :destroy, autosave: true # rubocop:disable Cop/ActiveRecordDependent
  has_many :u2f_registrations, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :chat_names, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  # Groups
  has_many :members, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :group_members, -> { where(requested_at: nil) }, dependent: :destroy, source: 'GroupMember' # rubocop:disable Cop/ActiveRecordDependent
  has_many :groups, through: :group_members
  has_many :owned_groups, -> { where members: { access_level: Gitlab::Access::OWNER } }, through: :group_members, source: :group
  has_many :masters_groups, -> { where members: { access_level: Gitlab::Access::MASTER } }, through: :group_members, source: :group

  # Projects
  has_many :groups_projects,          through: :groups, source: :projects
  has_many :personal_projects,        through: :namespace, source: :projects
  has_many :project_members, -> { where(requested_at: nil) }, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :projects,                 through: :project_members
  has_many :created_projects,         foreign_key: :creator_id, class_name: 'Project'
  has_many :users_star_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :starred_projects, through: :users_star_projects, source: :project
  has_many :project_authorizations
  has_many :authorized_projects, through: :project_authorizations, source: :project

  has_many :snippets,                 dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :notes,                    dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :issues,                   dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :merge_requests,           dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :events,                   dependent: :destroy, foreign_key: :author_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :subscriptions,            dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :recent_events, -> { order "id DESC" }, foreign_key: :author_id,   class_name: "Event"
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_one  :abuse_report,             dependent: :destroy, foreign_key: :user_id # rubocop:disable Cop/ActiveRecordDependent
  has_many :reported_abuse_reports,   dependent: :destroy, foreign_key: :reporter_id, class_name: "AbuseReport" # rubocop:disable Cop/ActiveRecordDependent
  has_many :spam_logs,                dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :builds,                   dependent: :nullify, class_name: 'Ci::Build' # rubocop:disable Cop/ActiveRecordDependent
  has_many :pipelines,                dependent: :nullify, class_name: 'Ci::Pipeline' # rubocop:disable Cop/ActiveRecordDependent
  has_many :todos,                    dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :notification_settings,    dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :award_emoji,              dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :triggers,                 dependent: :destroy, class_name: 'Ci::Trigger', foreign_key: :owner_id # rubocop:disable Cop/ActiveRecordDependent

  has_many :issue_assignees
  has_many :assigned_issues, class_name: "Issue", through: :issue_assignees, source: :issue
  has_many :assigned_merge_requests,  dependent: :nullify, foreign_key: :assignee_id, class_name: "MergeRequest" # rubocop:disable Cop/ActiveRecordDependent

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
  validates :username,
    dynamic_path: true,
    presence: true,
    uniqueness: { case_sensitive: false }

  validate :namespace_uniq, if: :username_changed?
  validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
  validate :unique_email, if: :email_changed?
  validate :owns_notification_email, if: :notification_email_changed?
  validate :owns_public_email, if: :public_email_changed?
  validate :signup_domain_valid?, on: :create, if: ->(user) { !user.created_by_id }
  validates :avatar, file_size: { maximum: 200.kilobytes.to_i }

  before_validation :sanitize_attrs
  before_validation :set_notification_email, if: :email_changed?
  before_validation :set_public_email, if: :public_email_changed?

  after_update :update_emails_with_primary_email, if: :email_changed?
  before_save :ensure_authentication_token, :ensure_incoming_email_token
  before_save :ensure_user_rights_and_limits, if: :external_changed?
  after_save :ensure_namespace_correct
  after_initialize :set_projects_limit
  after_destroy :post_destroy_hook

  # User's Layout preference
  enum layout: [:fixed, :fluid]

  # User's Dashboard preference
  # Note: When adding an option, it MUST go on the end of the array.
  enum dashboard: [:projects, :stars, :project_activity, :starred_project_activity, :groups, :todos]

  # User's Project preference
  #
  # Note: When adding an option, it MUST go on the end of the hash with a
  # number higher than the current max. We cannot move options and/or change
  # their numbers.
  #
  # We skip 0 because this was used by an option that has since been removed.
  enum project_view: { activity: 1, files: 2 }

  alias_attribute :private_token, :authentication_token

  delegate :path, to: :namespace, allow_nil: true, prefix: true

  accepts_nested_attributes_for :namespace

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
        "Your account has been blocked. Please contact your GitLab " \
          "administrator if you think this is an error."
      end
    end
  end

  mount_uploader :avatar, AvatarUploader
  has_many :uploads, as: :model, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  # Scopes
  scope :admins, -> { where(admin: true) }
  scope :blocked, -> { with_states(:blocked, :ldap_blocked) }
  scope :external, -> { where(external: true) }
  scope :active, -> { with_state(:active).non_internal }
  scope :without_projects, -> { where('id NOT IN (SELECT DISTINCT(user_id) FROM members WHERE user_id IS NOT NULL AND requested_at IS NULL)') }
  scope :subscribed_for_admin_email, -> { where(admin_email_unsubscribed_at: nil) }
  scope :ldap, -> { joins(:identities).where('identities.provider LIKE ?', 'ldap%') }
  scope :with_provider, ->(provider) do
    joins(:identities).where(identities: { provider: provider })
  end
  scope :todo_authors, ->(user_id, state) { where(id: Todo.where(user_id: user_id, state: state).select(:author_id)) }
  scope :order_recent_sign_in, -> { reorder(Gitlab::Database.nulls_last_order('last_sign_in_at', 'DESC')) }
  scope :order_oldest_sign_in, -> { reorder(Gitlab::Database.nulls_last_order('last_sign_in_at', 'ASC')) }

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
        where(conditions).find_by("lower(username) = :value OR lower(email) = :value", value: login.downcase)
      else
        find_by(conditions)
      end
    end

    def sort(method)
      case method.to_s
      when 'recent_sign_in' then order_recent_sign_in
      when 'oldest_sign_in' then order_oldest_sign_in
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

    def existing_member?(email)
      User.where(email: email).any? || Email.where(email: email).any?
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
      table   = arel_table
      pattern = "%#{query}%"

      order = <<~SQL
        CASE
          WHEN users.name = %{query} THEN 0
          WHEN users.username = %{query} THEN 1
          WHEN users.email = %{query} THEN 2
          ELSE 3
        END
      SQL

      where(
        table[:name].matches(pattern)
          .or(table[:email].matches(pattern))
          .or(table[:username].matches(pattern))
      ).reorder(order % { query: ActiveRecord::Base.connection.quote(query) }, :name)
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
        table[:name].matches(pattern)
          .or(table[:email].matches(pattern))
          .or(table[:username].matches(pattern))
          .or(table[:id].in(matched_by_emails_user_ids))
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
      find_by(id: Key.unscoped.select(:user_id).where(id: key_id))
    end

    def find_by_full_path(path, follow_redirects: false)
      namespace = Namespace.for_user.find_by_full_path(path, follow_redirects: follow_redirects)
      namespace&.owner
    end

    def non_ldap
      joins('LEFT JOIN identities ON identities.user_id = users.id')
        .where('identities.provider IS NULL OR identities.provider NOT LIKE ?', 'ldap%')
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
        u.notification_email = email
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
    where(Hash[internal_attributes.zip([[false, nil]] * internal_attributes.size)])
  end

  #
  # Instance methods
  #

  def to_param
    username
  end

  def to_reference(_from_project = nil, target_project: nil, full: nil)
    "#{self.class.reference_prefix}#{username}"
  end

  def skip_confirmation=(bool)
    skip_confirmation! if bool
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
    u2f_registrations.exists?
  end

  def namespace_uniq
    # Return early if username already failed the first uniqueness validation
    return if errors.key?(:username) &&
        errors[:username].include?('has already been taken')

    existing_namespace = Namespace.by_path(username)
    if existing_namespace && existing_namespace != namespace
      errors.add(:username, 'has already been taken')
    end
  end

  def avatar_type
    unless avatar.image?
      errors.add :avatar, "only images allowed"
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

  def update_emails_with_primary_email
    primary_email_record = emails.find_by(email: email)
    if primary_email_record
      Emails::DestroyService.new(self, email: email).execute
      Emails::CreateService.new(self, email: email_was).execute
    end
  end

  # Returns the groups a user has access to
  def authorized_groups
    union = Gitlab::SQL::Union
      .new([groups.select(:id), authorized_projects.select(:namespace_id)])

    Group.where("namespaces.id IN (#{union.to_sql})")
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

  def require_ssh_key?
    keys.count == 0 && Gitlab::ProtocolAccess.allowed?('ssh')
  end

  def require_password_creation?
    password_automatically_set? && allow_password_authentication?
  end

  def require_personal_access_token_creation_for_git_auth?
    return false if allow_password_authentication? || ldap_user?

    PersonalAccessTokensFinder.new(user: self, impersonation: false, state: 'active').execute.none?
  end

  def allow_password_authentication?
    !ldap_user? && current_application_settings.password_authentication_enabled?
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

  def first_name
    name.split.first unless name.blank?
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
        merge_requests = MergeRequest.where("created_at >= ?", event.created_at)
          .where(source_project_id: project.id,
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
    links = ForkedProjectLink.where(
      forked_from_project_id: project,
      forked_to_project_id: personal_projects.unscope(:order)
    )
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
    %w[username skype linkedin twitter].each do |attr|
      value = public_send(attr)
      public_send("#{attr}=", Sanitize.clean(value)) if value.present?
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
    return unless has_attribute?(:projects_limit)

    connection_default_value_defined = new_record? && !projects_limit_changed?
    return unless projects_limit.nil? || connection_default_value_defined

    self.projects_limit = current_application_settings.default_projects_limit
  end

  def requires_ldap_check?
    if !Gitlab.config.ldap.enabled
      false
    elsif ldap_user?
      !last_credential_check_at || (last_credential_check_at + Gitlab.config.ldap['sync_time']) < Time.now
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
      public_send("#{k}=", v)
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

  def avatar_url(size: nil, scale: 2, **args)
    # We use avatar_path instead of overriding avatar_url because of carrierwave.
    # See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11001/diffs#note_28659864
    avatar_path(args) || GravatarService.new.execute(email, size, scale, username: username)
  end

  def all_emails
    all_emails = []
    all_emails << email unless temp_oauth_email?
    all_emails.concat(emails.map(&:email))
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
    create_namespace!(path: username, name: username) unless namespace

    if username_changed?
      namespace.update_attributes(path: username, name: username)
    end
  end

  def post_destroy_hook
    log_info("User \"#{name}\" (#{email})  was removed")
    system_hook_service.execute_hooks_for(self, :destroy)
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

  def admin_unsubscribe!
    update_column :admin_email_unsubscribed_at, Time.now
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
    @manageable_namespaces ||= [namespace] + owned_groups + masters_groups
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
        .where("ci_runner_projects.project_id IN (#{ci_projects_union.to_sql})")
        .select(:runner_id)
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

  def update_cache_counts
    assigned_open_merge_requests_count(force: true)
    assigned_open_issues_count(force: true)
  end

  def invalidate_cache_counts
    invalidate_issue_cache_counts
    invalidate_merge_request_cache_counts
  end

  def invalidate_issue_cache_counts
    Rails.cache.delete(['users', id, 'assigned_open_issues_count'])
  end

  def invalidate_merge_request_cache_counts
    Rails.cache.delete(['users', id, 'assigned_open_merge_requests_count'])
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
      Users::UpdateService.new(self).execute(validate: false)
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

  protected

  # override, from Devise::Validatable
  def password_required?
    return false if internal?
    super
  end

  private

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
      self.can_create_group = gitlab_config.default_can_create_group
      self.projects_limit = current_application_settings.default_projects_limit
    end
  end

  def signup_domain_valid?
    valid = true
    error = nil

    if current_application_settings.domain_blacklist_enabled?
      blocked_domains = current_application_settings.domain_blacklist
      if domain_matches?(blocked_domains, email)
        error = 'is not from an allowed domain.'
        valid = false
      end
    end

    allowed_domains = current_application_settings.domain_whitelist
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

    Users::UpdateService.new(user).execute(validate: false)
    user
  ensure
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end
end
