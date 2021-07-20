# frozen_string_literal: true

class Member < ApplicationRecord
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

  AVATAR_SIZE = 40
  ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT = 10

  attr_accessor :raw_invite_token

  belongs_to :created_by, class_name: "User"
  belongs_to :user
  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  delegate :name, :username, :email, to: :user, prefix: true

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
  validates :user_id,
    uniqueness: {
      message: _('project bots cannot be added to other groups / projects')
    },
    if: :project_bot?

  scope :in_hierarchy, ->(source) do
    groups = source.root_ancestor.self_and_descendants
    group_members = Member.default_scoped.where(source: groups)

    projects = source.root_ancestor.all_projects
    project_members = Member.default_scoped.where(source: projects)

    Member.default_scoped.from_union([
      group_members,
      project_members
    ]).merge(self)
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

  scope :connected_to_user, -> { where.not(user_id: nil) }

  # This scope is exclusively used to get the members
  # that can possibly have project_authorization records
  # to projects/groups.
  scope :authorizable, -> do
    connected_to_user
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

  scope :without_invites_and_requests, -> do
    non_request
      .non_invite
      .non_minimal_access
  end

  scope :invite, -> { where.not(invite_token: nil) }
  scope :non_invite, -> { where(invite_token: nil) }

  scope :request, -> { where.not(requested_at: nil) }
  scope :non_request, -> { where(requested_at: nil) }

  scope :not_accepted_invitations, -> { invite.where(invite_accepted_at: nil) }
  scope :not_accepted_invitations_by_user, -> (user) { not_accepted_invitations.where(created_by: user) }
  scope :not_expired, -> (today = Date.current) { where(arel_table[:expires_at].gt(today).or(arel_table[:expires_at].eq(nil))) }

  scope :created_today, -> do
    now = Date.current
    where(created_at: now.beginning_of_day..now.end_of_day)
  end
  scope :last_ten_days_excluding_today, -> (today = Date.current) { where(created_at: (today - 10).beginning_of_day..(today - 1).end_of_day) }

  scope :has_access, -> { active.where('access_level > 0') }

  scope :guests, -> { active.where(access_level: GUEST) }
  scope :reporters, -> { active.where(access_level: REPORTER) }
  scope :developers, -> { active.where(access_level: DEVELOPER) }
  scope :maintainers, -> { active.where(access_level: MAINTAINER) }
  scope :non_guests, -> { where('members.access_level > ?', GUEST) }
  scope :non_minimal_access, -> { where('members.access_level > ?', MINIMAL_ACCESS) }
  scope :owners, -> { active.where(access_level: OWNER) }
  scope :owners_and_maintainers, -> { active.where(access_level: [OWNER, MAINTAINER]) }
  scope :with_user, -> (user) { where(user: user) }
  scope :with_user_by_email, -> (email) { left_join_users.where(users: { email: email } ) }

  scope :preload_user_and_notification_settings, -> { preload(user: :notification_settings) }

  scope :with_source_id, ->(source_id) { where(source_id: source_id) }
  scope :including_source, -> { includes(:source) }

  scope :distinct_on_user_with_max_access_level, -> do
    distinct_members = select('DISTINCT ON (user_id, invite_email) *')
                       .order('user_id, invite_email, access_level DESC, expires_at DESC, created_at ASC')

    unscoped.from(distinct_members, :members)
  end

  scope :order_name_asc, -> { left_join_users.reorder(Gitlab::Database.nulls_last_order('users.name', 'ASC')) }
  scope :order_name_desc, -> { left_join_users.reorder(Gitlab::Database.nulls_last_order('users.name', 'DESC')) }
  scope :order_recent_sign_in, -> { left_join_users.reorder(Gitlab::Database.nulls_last_order('users.last_sign_in_at', 'DESC')) }
  scope :order_oldest_sign_in, -> { left_join_users.reorder(Gitlab::Database.nulls_last_order('users.last_sign_in_at', 'ASC')) }

  scope :on_project_and_ancestors, ->(project) { where(source: [project] + project.ancestors) }

  before_validation :generate_invite_token, on: :create, if: -> (member) { member.invite_email.present? }

  after_create :send_invite, if: :invite?, unless: :importing?
  after_create :send_request, if: :request?, unless: :importing?
  after_create :create_notification_setting, unless: [:pending?, :importing?]
  after_create :post_create_hook, unless: [:pending?, :importing?], if: :hook_prerequisites_met?
  after_update :post_update_hook, unless: [:pending?, :importing?], if: :hook_prerequisites_met?
  after_destroy :destroy_notification_setting
  after_destroy :post_destroy_hook, unless: :pending?, if: :hook_prerequisites_met?
  after_commit :refresh_member_authorized_projects

  default_value_for :notification_level, NotificationSetting.levels[:global]

  class << self
    def search(query)
      joins(:user).merge(User.search(query))
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

    def sort_by_attribute(method)
      case method.to_s
      when 'access_level_asc' then reorder(access_level: :asc)
      when 'access_level_desc' then reorder(access_level: :desc)
      when 'recent_sign_in' then order_recent_sign_in
      when 'oldest_sign_in' then order_oldest_sign_in
      when 'last_joined' then order_created_desc
      when 'oldest_joined' then order_created_asc
      else
        order_by(method)
      end
    end

    def left_join_users
      users = User.arel_table
      members = Member.arel_table

      member_users = members.join(users, Arel::Nodes::OuterJoin)
                             .on(members[:user_id].eq(users[:id]))
                             .join_sources

      joins(member_users)
    end

    def access_for_user_ids(user_ids)
      where(user_id: user_ids).has_access.pluck(:user_id, :access_level).to_h
    end

    def find_by_invite_token(raw_invite_token)
      invite_token = Devise.token_generator.digest(self, :invite_token, raw_invite_token)
      find_by(invite_token: invite_token)
    end

    def valid_email?(email)
      Devise.email_regexp.match?(email)
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

  def accept_request
    return false unless request?

    updated = self.update(requested_at: nil)
    after_accept_request if updated

    updated
  end

  def accept_invite!(new_user)
    return false unless invite?

    self.invite_token = nil
    self.invite_accepted_at = Time.current.utc

    self.user = new_user

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

    run_after_commit_or_now { notification_service.invite_member_reminder(self, @raw_invite_token, reminder_index) }
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

      GroupMember.where(source: source.ancestors, user_id: user_id).order(:access_level).last
    end
  end

  def invite_to_unknown_user?
    invite? && user_id.nil?
  end

  def created_by_name
    created_by&.name
  end

  private

  def send_invite
    # override in subclass
  end

  def send_request
    notification_service.new_access_request(self)
  end

  def post_create_hook
    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_update_hook
    system_hook_service.execute_hooks_for(self, :update)
  end

  def post_destroy_hook
    system_hook_service.execute_hooks_for(self, :destroy)
  end

  # Refreshes authorizations of the current member.
  #
  # This method schedules a job using Sidekiq and as such **must not** be called
  # in a transaction. Doing so can lead to the job running before the
  # transaction has been committed, resulting in the job either throwing an
  # error or not doing any meaningful work.
  # rubocop: disable CodeReuse/ServiceClass
  def refresh_member_authorized_projects
    # If user/source is being destroyed, project access are going to be
    # destroyed eventually because of DB foreign keys, so we shouldn't bother
    # with refreshing after each member is destroyed through association
    return if destroyed_by_association.present?

    UserProjectAccessChangedService.new(user_id).execute
  end
  # rubocop: enable CodeReuse/ServiceClass

  def after_accept_invite
    post_create_hook
  end

  def after_decline_invite
    # override in subclass
  end

  def after_accept_request
    post_create_hook
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

  def notifiable_options
    {}
  end

  def higher_access_level_than_group
    if highest_group_member && highest_group_member.access_level > access_level
      error_parameters = { access: highest_group_member.human_access, group_name: highest_group_member.group.name }

      errors.add(:access_level, s_("should be greater than or equal to %{access} inherited membership from group %{group_name}") % error_parameters)
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
end

Member.prepend_mod_with('Member')
