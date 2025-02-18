# frozen_string_literal: true

class Member < ApplicationRecord
  extend ::Gitlab::Utils::Override
  include EachBatch
  include AfterCommitQueue
  include Sortable
  include Importable
  include CreatedAtFilterable
  include Expirable
  include Gitlab::Access
  include Presentable
  include Gitlab::Utils::StrongMemoize
  include FromUnion
  include UpdateHighestRole
  include RestrictedSignup
  include Gitlab::Experiment::Dsl

  ignore_column :last_activity_on, remove_with: '17.8', remove_after: '2024-12-23'

  AVATAR_SIZE = 40
  ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT = 10

  STATE_ACTIVE = 0
  STATE_AWAITING = 1

  attr_accessor :raw_invite_token

  belongs_to :created_by, class_name: "User"
  belongs_to :user
  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :member_namespace, inverse_of: :namespace_members, foreign_key: 'member_namespace_id', class_name: 'Namespace'

  delegate :name, :username, :email, :last_activity_on, to: :user, prefix: true

  has_many :member_approvals, inverse_of: :member, class_name: 'Members::MemberApproval'

  validates :expires_at, allow_blank: true, future_date: true
  validates :user, presence: true, unless: :invite?
  validates :source, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id],
                                    message: "already exists in source",
                                    allow_nil: true }
  validate :higher_access_level_than_group, unless: :importing?
  validates :invite_email,
    presence: {
      if: :invite?
    },
    devise_email: {
      allow_nil: true
    },
    uniqueness: {
      scope: [:source_type, :source_id],
      allow_nil: true
    }
  validate :signup_email_valid?, on: :create, if: ->(member) { member.invite_email.present? }
  validates :user_id,
    uniqueness: {
      message: N_('project bots cannot be added to other groups / projects')
    },
    if: :project_bot?
  validate :access_level_inclusion
  validate :user_is_not_placeholder

  scope :with_invited_user_state, -> do
    joins('LEFT JOIN users as invited_user ON invited_user.email = members.invite_email')
    .select('members.*', 'invited_user.state as invited_user_state')
    .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/417456")
  end

  scope :in_hierarchy, ->(source) do
    source = source.root_ancestor
    groups = source.self_and_descendants
    group_members = Member.default_scoped.where(source: groups).select(*Member.cached_column_list)

    projects = source.root_ancestor.all_projects
    project_members = Member.default_scoped.where(source: projects).select(*Member.cached_column_list)

    Member.default_scoped.from_union([group_members, project_members]).merge(self)
  end

  scope :for_self_and_descendants, ->(group, columns = Member.cached_column_list) do
    return self if group.blank?

    group_members = where(source_id: group.self_and_descendant_ids, source_type: GroupMember::SOURCE_TYPE)
    project_members = where(source_id: group.all_project_ids, source_type: ProjectMember::SOURCE_TYPE)

    Member.unscoped.from_union([
      group_members.select(*columns),
      project_members.select(*columns)
    ], remove_duplicates: false)
  end

  scope :including_user_ids, ->(user_ids) do
    where(user_id: user_ids)
  end

  scope :excluding_users, ->(user_ids) do
    where.not(user_id: user_ids)
  end

  scope :count_by_access_level, ->(column_name = nil) do
    group(:access_level).count(column_name)
  end

  # This scope encapsulates (most of) the conditions a row in the member table
  # must satisfy if it is a valid permission. Of particular note:
  #
  #   * Access requests must be excluded
  #   * Blocked users must be excluded
  #   * Invitations take effect immediately
  #   * expires_at is not implemented. A background worker purges expired rows
  scope :active, -> do
    is_external_invite = arel_table[:user_id].eq(nil).and(arel_table[:invite_token].not_eq(nil))
    user_is_active = User.arel_table[:state].eq(:active)

    user_ok = Arel::Nodes::Grouping.new(is_external_invite).or(user_is_active)

    left_join_users
      .where(user_ok)
      .non_request
      .non_minimal_access
      .reorder(nil)
  end

  scope :blocked, -> do
    is_external_invite = arel_table[:user_id].eq(nil).and(arel_table[:invite_token].not_eq(nil))
    user_is_blocked = User.arel_table[:state].eq(:blocked)

    left_join_users
      .where(user_is_blocked)
      .where.not(is_external_invite)
      .non_request
      .non_minimal_access
      .reorder(nil)
  end

  scope :active_state, -> { where(state: STATE_ACTIVE) }

  scope :connected_to_user, -> { where.not(user_id: nil) }

  # This scope is exclusively used to get the members
  # that can possibly have project_authorization records
  # to projects/groups.
  scope :authorizable, -> do
    connected_to_user
      .active_state
      .non_request
      .non_minimal_access
  end

  # Like active, but without invites. For when a User is required.
  scope :active_without_invites_and_requests, -> do
    left_join_users
      .where(users: { state: 'active' })
      .without_invites_and_requests
      .reorder(nil)
  end

  scope :without_invites_and_requests, ->(minimal_access: false) do
    result = active_state.non_request.non_invite

    result = result.non_minimal_access unless minimal_access

    result
  end

  scope :invite, -> { where.not(invite_token: nil) }
  scope :non_invite, -> { where(invite_token: nil) }
  scope :with_case_insensitive_invite_emails, ->(emails) do
    where(arel_table[:invite_email].lower.in(emails.map(&:downcase)))
  end

  scope :request, -> { where.not(requested_at: nil) }
  scope :non_request, -> { where(requested_at: nil) }

  scope :not_accepted_invitations, -> { invite.where(invite_accepted_at: nil) }
  scope :not_accepted_invitations_by_user, ->(user) { not_accepted_invitations.where(created_by: user) }
  scope :not_expired, ->(today = Date.current) { where(arel_table[:expires_at].gt(today).or(arel_table[:expires_at].eq(nil))) }
  scope :expiring_and_not_notified, ->(date) { where("expiry_notified_at is null AND expires_at >= ? AND expires_at <= ?", Date.current, date) }
  scope :with_created_by, -> { where.associated(:created_by) }

  scope :created_today, -> do
    now = Date.current
    where(created_at: now.beginning_of_day..now.end_of_day)
  end
  scope :last_ten_days_excluding_today, ->(today = Date.current) { where(created_at: (today - 10).beginning_of_day..(today - 1).end_of_day) }

  scope :has_access, -> { active.where('access_level > 0') }

  scope :guests, -> { active.where(access_level: GUEST) }
  scope :planners, -> { active.where(access_level: PLANNER) }
  scope :reporters, -> { active.where(access_level: REPORTER) }
  scope :developers, -> { active.where(access_level: DEVELOPER) }
  scope :maintainers, -> { active.where(access_level: MAINTAINER) }
  scope :non_guests, -> { where('members.access_level > ?', GUEST) }
  scope :non_minimal_access, -> { where('members.access_level > ?', MINIMAL_ACCESS) }
  scope :owners, -> { active.where(access_level: OWNER) }
  scope :all_owners, -> { where(access_level: OWNER) }
  scope :owners_and_maintainers, -> { active.where(access_level: [OWNER, MAINTAINER]) }
  scope :with_user, ->(user) { where(user: user) }
  scope :by_access_level, ->(access_level) { active.where(access_level: access_level) }
  scope :all_by_access_level, ->(access_level) { where(access_level: access_level) }
  scope :with_at_least_access_level, ->(access_level) { where(access_level: access_level..) }

  scope :preload_users, -> { preload(:user) }

  scope :preload_user_and_notification_settings, -> do
    preload(user: :notification_settings)
      .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/417456")
  end

  scope :with_source_id, ->(source_id) { where(source_id: source_id) }
  scope :including_source, -> { includes(:source) }
  scope :including_user, -> { includes(:user) }

  scope :distinct_on_user_with_max_access_level, ->(for_object) do
    valid_objects = %w[Project Namespace]
    obj_class = if for_object.is_a?(Group)
                  'Namespace'
                else
                  for_object.class.name
                end

    raise ArgumentError, "Invalid object: #{obj_class}" unless valid_objects.include?(obj_class)

    # in case a user has same access_level in multiple groups/project, we always want to retrieve the one
    # that belongs to the object we request for
    order = <<~SQL
      user_id, invite_email,
      CASE WHEN source_id = #{for_object.id} and source_type = '#{obj_class}'
      THEN access_level + 1 ELSE access_level END DESC,
      member_role_id ASC, expires_at DESC, created_at ASC
    SQL

    distinct_members = select('DISTINCT ON (user_id, invite_email) *')
                       .order(Arel.sql(order))

    unscoped.from(distinct_members, :members)
  end

  scope :distinct_on_source_and_case_insensitive_invite_email, -> do
    select('DISTINCT ON (source_id, source_type, LOWER(invite_email)) members.*')
      .order('source_id, source_type, LOWER(invite_email)')
  end

  scope :order_name_asc, -> do
    build_keyset_order_on_joined_column(
      scope: left_join_users,
      attribute_name: 'member_user_full_name',
      column: User.arel_table[:name],
      direction: :asc,
      nullable: :nulls_last
    )
  end

  scope :order_name_desc, -> do
    build_keyset_order_on_joined_column(
      scope: left_join_users,
      attribute_name: 'member_user_full_name',
      column: User.arel_table[:name],
      direction: :desc,
      nullable: :nulls_last
    )
  end

  scope :order_oldest_sign_in, -> do
    build_keyset_order_on_joined_column(
      scope: left_join_users,
      attribute_name: 'member_user_last_sign_in_at',
      column: User.arel_table[:last_sign_in_at],
      direction: :asc,
      nullable: :nulls_last
    )
  end

  scope :order_recent_sign_in, -> do
    build_keyset_order_on_joined_column(
      scope: left_join_users,
      attribute_name: 'member_user_last_sign_in_at',
      column: User.arel_table[:last_sign_in_at],
      direction: :desc,
      nullable: :nulls_last
    )
  end

  scope :order_oldest_last_activity, -> do
    build_keyset_order_on_joined_column(
      scope: left_join_users,
      attribute_name: 'member_user_last_activity_on',
      column: User.arel_table[:last_activity_on],
      direction: :asc,
      nullable: :nulls_first
    )
  end

  scope :order_recent_last_activity, -> do
    build_keyset_order_on_joined_column(
      scope: left_join_users,
      attribute_name: 'member_user_last_activity_on',
      column: User.arel_table[:last_activity_on],
      direction: :desc,
      nullable: :nulls_last
    )
  end

  scope :order_oldest_created_user, -> do
    build_keyset_order_on_joined_column(
      scope: left_join_users,
      attribute_name: 'member_user_created_at',
      column: User.arel_table[:created_at],
      direction: :asc,
      nullable: :nulls_first
    )
  end

  scope :order_recent_created_user, -> do
    build_keyset_order_on_joined_column(
      scope: left_join_users,
      attribute_name: 'member_user_created_at',
      column: User.arel_table[:created_at],
      direction: :desc,
      nullable: :nulls_last
    )
  end

  scope :order_updated_desc, -> { order(updated_at: :desc) }
  scope :on_project_and_ancestors, ->(project) { where(source: [project] + project.ancestors) }
  scope :with_static_role, -> { where(member_role_id: nil) }

  before_validation :set_member_namespace_id, on: :create
  before_validation :generate_invite_token, on: :create, if: ->(member) { member.invite_email.present? && !member.invite_accepted_at? }

  after_create :send_invite, if: :invite?, unless: :importing?
  after_create :create_notification_setting, unless: [:pending?, :importing?]
  after_create :post_create_member_hook, unless: [:pending?, :importing?], if: :hook_prerequisites_met?
  after_create :post_create_access_request_hook, if: [:request?, :hook_prerequisites_met?]
  after_create :update_two_factor_requirement, unless: :invite?
  after_create :create_organization_user_record
  after_update :post_update_hook, unless: [:pending?, :importing?], if: :hook_prerequisites_met?
  after_update :create_organization_user_record, if: :accepted_invite_or_request?
  after_destroy :destroy_notification_setting
  after_destroy :post_destroy_member_hook, unless: :pending?, if: :hook_prerequisites_met?
  after_destroy :post_destroy_access_request_hook, if: [:request?, :hook_prerequisites_met?]
  after_destroy :update_two_factor_requirement, unless: :invite?
  after_save :log_invitation_token_cleanup

  after_commit :send_request, if: :request?, unless: :importing?, on: [:create]
  after_commit on: [:create, :update, :destroy], unless: :importing? do
    refresh_member_authorized_projects
  end

  attribute :notification_level, default: -> { NotificationSetting.levels[:global] }
  # Only false when the current user is a member of the shared group or project but not of the invited private group
  # so the current user can't see the source of the membership.
  attribute :is_source_accessible_to_current_user, default: true

  class << self
    def search(query)
      scope = joins(:user)
                .merge(User.search(query, use_minimum_char_limit: false))
                .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/417456")

      return scope unless Gitlab::Pagination::Keyset::Order.keyset_aware?(scope)

      # If the User.search method returns keyset pagination aware AR scope then we
      # need call apply_cursor_conditions which adds the ORDER BY columns from the scope
      # to the SELECT clause.
      #
      # Why is this needed:
      # When using keyset pagination, the next page is loaded using the ORDER BY
      # values of the last record (cursor). This query selects `members.*` and
      # orders by a custom SQL expression on `users` and `users.name`. The values
      # will not be part of `members.*`.
      #
      # Result: `SELECT members.*, users.column1, users.column2 FROM members ...`
      order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(scope)
      order.apply_cursor_conditions(scope).reorder(order)
    end

    def search_invite_email(query)
      invite.where(['invite_email ILIKE ?', "%#{query}%"])
    end

    def filter_by_2fa(value)
      case value
      when 'enabled'
        left_join_users.merge(User.with_two_factor)
      when 'disabled'
        left_join_users.merge(User.without_two_factor)
      else
        all
      end
    end

    def filter_by_user_type(value)
      return unless ::User.user_types.key?(value)

      left_join_users.merge(::User.where(user_type: value))
    end

    def sort_by_attribute(method)
      case method.to_s
      when 'access_level_asc' then reorder(access_level: :asc)
      when 'access_level_desc' then reorder(access_level: :desc)
      when 'recent_sign_in' then order_recent_sign_in
      when 'oldest_sign_in' then order_oldest_sign_in
      when 'recent_created_user' then order_recent_created_user
      when 'oldest_created_user' then order_oldest_created_user
      when 'recent_last_activity' then order_recent_last_activity
      when 'oldest_last_activity' then order_oldest_last_activity
      when 'last_joined' then order_created_desc
      when 'oldest_joined' then order_created_asc
      else
        order_by(method)
      end
    end

    def left_join_users
      left_outer_joins(:user)
        .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/417456")
    end

    def access_for_user_ids(user_ids)
      with_user(user_ids).has_access.pluck(:user_id, :access_level).to_h
    end

    def find_by_invite_token(raw_invite_token)
      invite_token = Devise.token_generator.digest(self, :invite_token, raw_invite_token)
      find_by(invite_token: invite_token)
    end

    def valid_email?(email)
      Devise.email_regexp.match?(email)
    end

    def pluck_user_ids
      pluck(:user_id)
    end

    def coerce_to_no_access
      select(member_columns_with_no_access)
    end

    def with_group_group_sharing_access(shared_groups, custom_role_for_group_link_enabled)
      columns = member_columns_with_group_sharing_access(custom_role_for_group_link_enabled)

      joins("LEFT OUTER JOIN group_group_links ON members.source_id = group_group_links.shared_with_group_id")
        .select(columns)
        .where(group_group_links: { shared_group_id: shared_groups })
    end

    private

    def member_columns_with_group_sharing_access(custom_role_for_group_link_enabled)
      group_group_link_table = GroupGroupLink.arel_table

      column_names.map do |column_name|
        case column_name
        when 'access_level'
          args = [group_group_link_table[:group_access], arel_table[:access_level]]
          smallest_value_arel(args, 'access_level')
        when 'member_role_id'
          member_role_id(group_group_link_table, custom_role_for_group_link_enabled)
        else
          arel_table[column_name]
        end
      end
    end

    def member_columns_with_no_access
      column_names.map { |column_name| column_name == 'access_level' ? no_access_arel : arel_table[column_name] }
    end

    def smallest_value_arel(args, column_alias)
      Arel::Nodes::As.new(Arel::Nodes::NamedFunction.new('LEAST', args), Arel::Nodes::SqlLiteral.new(column_alias))
    end

    def no_access_arel
      Arel::Nodes::As.new(Arel::Nodes::SqlLiteral.new('0'), Arel::Nodes::SqlLiteral.new('access_level'))
    end

    # overriden in EE
    def member_role_id(_group_link_table, _custom_role_for_group_link_enabled)
      arel_table[:member_role_id]
    end
  end

  def real_source_type
    source_type
  end

  def access_field
    access_level
  end

  def invite?
    self.invite_token.present?
  end

  def request?
    requested_at.present?
  end

  def pending?
    invite? || request?
  end

  def hook_prerequisites_met?
    # It is essential that an associated user record exists
    # so that we can successfully fire any member related hooks/notifications.
    user.present?
  end

  def accept_request(current_user)
    return false unless request?

    updated = self.update(requested_at: nil, created_by: current_user, request_accepted_at: Time.current.utc)
    after_accept_request if updated

    updated
  end

  def accept_invite!(new_user)
    return false unless invite?
    return false unless new_user

    self.user = new_user
    return false unless self.user.save

    self.invite_token = nil
    self.invite_accepted_at = Time.current.utc

    saved = self.save

    after_accept_invite if saved

    saved
  end

  def decline_invite!
    return false unless invite?

    destroyed = self.destroy

    after_decline_invite if destroyed

    destroyed
  end

  def generate_invite_token
    raw, enc = Devise.token_generator.generate(self.class, :invite_token)
    @raw_invite_token = raw
    self.invite_token = enc
  end

  def generate_invite_token!
    generate_invite_token && save(validate: false)
  end

  def resend_invite
    return unless invite?

    generate_invite_token! unless @raw_invite_token

    send_invite
  end

  def send_invitation_reminder(reminder_index)
    return unless invite?

    generate_invite_token! unless @raw_invite_token

    run_after_commit_or_now do
      Members::InviteReminderMailer.email(self, @raw_invite_token, reminder_index).deliver_later
    end
  end

  def create_notification_setting
    user.notification_settings.find_or_create_for(source)
  end

  def destroy_notification_setting
    notification_setting&.destroy
  end

  def notification_setting
    @notification_setting ||= user&.notification_settings_for(source)
  end

  # rubocop: disable CodeReuse/ServiceClass
  def notifiable?(type, opts = {})
    # always notify when there isn't a user yet
    return true if user.blank?

    NotificationRecipients::BuildService.notifiable?(user, type, notifiable_options.merge(opts))
  end
  # rubocop: enable CodeReuse/ServiceClass

  # Find the user's group member with a highest access level
  def highest_group_member
    strong_memoize(:highest_group_member) do
      next unless user_id && source&.ancestors&.any?

      GroupMember
        .where(source: source.ancestors, user_id: user_id)
        .non_request
        .order(:access_level).last
    end
  end

  def invite_to_unknown_user?
    invite? && user_id.nil?
  end

  def created_by_name
    created_by&.name
  end

  def update_two_factor_requirement
    return unless source.is_a?(Group)
    return unless user

    Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
      %w[users user_details user_preferences], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424288'
    ) do
      user.update_two_factor_requirement
    end
  end

  def prevent_role_assignement?(_current_user, _params)
    false
  end

  private

  # TODO: https://gitlab.com/groups/gitlab-org/-/epics/7054
  # temporary until we can we properly remove the source columns
  def set_member_namespace_id
    self.member_namespace_id = self.source_id
  end

  def access_level_inclusion
    return if access_level.in?(Gitlab::Access.all_values)

    errors.add(:access_level, "is not included in the list")
  end

  def user_is_not_placeholder
    if Gitlab::Import::PlaceholderUserCreator.placeholder_email?(invite_email)
      errors.add(:invite_email, _('must not be a placeholder email'))
    elsif user&.placeholder?
      errors.add(:user_id, _("must not be a placeholder user"))
    end
  end

  def send_invite
    run_after_commit_or_now { Members::InviteMailer.initial_email(self, @raw_invite_token).deliver_later }
  end

  def send_request
    notification_service.new_access_request(self)
    todo_service.create_member_access_request_todos(self)
  end

  def post_create_access_request_hook
    system_hook_service.execute_hooks_for(self, :request)
  end

  def post_create_member_hook
    # The creator of a personal project gets added as a `ProjectMember`
    # with `OWNER` access during creation of a personal project,
    # but we do not want to trigger notifications to the same person who created the personal project.
    unless source.is_a?(Project) && source.personal_namespace_holder?(user)
      event_service.join_source(source, user)
      run_after_commit_or_now { notification_service.new_member(self) }
    end

    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_update_hook
    if saved_change_to_access_level?
      run_after_commit { notification_service.updated_member_access_level(self) }
    end

    if saved_change_to_expires_at?
      run_after_commit { notification_service.updated_member_expiration(self) }
    end

    system_hook_service.execute_hooks_for(self, :update)
  end

  def post_destroy_member_hook
    system_hook_service.execute_hooks_for(self, :destroy)
  end

  def post_destroy_access_request_hook
    system_hook_service.execute_hooks_for(self, :revoke)
  end

  # Refreshes authorizations of the current member.
  #
  # This method schedules a job using Sidekiq and as such **must not** be called
  # in a transaction. Doing so can lead to the job running before the
  # transaction has been committed, resulting in the job either throwing an
  # error or not doing any meaningful work.
  # rubocop: disable CodeReuse/ServiceClass

  # This method is overridden in the test environment, see stubbed_member.rb
  def refresh_member_authorized_projects
    UserProjectAccessChangedService.new(user_id).execute
  end
  # rubocop: enable CodeReuse/ServiceClass

  def after_accept_invite
    run_after_commit_or_now do
      notification_service.accept_invite(self)
    end

    update_two_factor_requirement

    post_create_member_hook
  end

  def after_decline_invite
    Members::InviteDeclinedMailer.with(member: self).email.deliver_later
  end

  def after_accept_request
    post_create_member_hook
  end

  # rubocop: disable CodeReuse/ServiceClass
  def system_hook_service
    SystemHooksService.new
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def notification_service
    NotificationService.new
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def todo_service
    TodoService.new
  end
  # rubocop: enable CodeReuse/ServiceClass

  def notifiable_options
    case source
    when Group
      { group: source }
    when Project
      { project: source }
    end
  end

  def higher_access_level_than_group
    if access_level && highest_group_member && highest_group_member.access_level > access_level
      error_parameters = { access: highest_group_member.human_access, group_name: highest_group_member.group.name }

      errors.add(:access_level, s_("should be greater than or equal to %{access} inherited membership from group %{group_name}") % error_parameters)
    end
  end

  def signup_email_valid?
    error = validate_admin_signup_restrictions(invite_email)

    errors.add(:user, error) if error
  end

  def signup_email_invalid_message
    if source_type == 'Project'
      _("is not allowed for this project.")
    else
      _("is not allowed for this group.")
    end
  end

  def update_highest_role?
    return unless user_id.present?

    previous_changes[:access_level].present? || destroyed?
  end

  def update_highest_role_attribute
    user_id
  end

  def project_bot?
    user&.project_bot?
  end

  def log_invitation_token_cleanup
    return true unless Gitlab.com? && invite? && invite_accepted_at?

    error = StandardError.new("Invitation token is present but invite was already accepted!")
    Gitlab::ErrorTracking.track_exception(error, attributes.slice(%w["invite_accepted_at created_at source_type source_id user_id id"]))
  end

  def event_service
    EventCreateService.new # rubocop:todo CodeReuse/ServiceClass -- Legacy, convert to value object eventually
  end

  def create_organization_user_record
    return if pending?
    return if source.organization.blank?

    Organizations::OrganizationUser.create_organization_record_for(user_id, source.organization_id)
  end

  def accepted_invite_or_request?
    # `user_id` is nil for member invited through email and will be set once the user has created an account.
    # `requested_at` is defined only while the membership access request is still pending.
    saved_change_to_user_id? || saved_change_to_requested_at?
  end
end

Member.prepend_mod_with('Member')
