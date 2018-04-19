class Member < ActiveRecord::Base
  include AfterCommitQueue
  include Sortable
  include Importable
  include Expirable
  include Gitlab::Access
  include Presentable

  attr_accessor :raw_invite_token

  belongs_to :created_by, class_name: "User"
  belongs_to :user
  belongs_to :source, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  delegate :name, :username, :email, to: :user, prefix: true

  validates :user, presence: true, unless: :invite?
  validates :source, presence: true
  validates :user_id, uniqueness: { scope: [:source_type, :source_id],
                                    message: "already exists in source",
                                    allow_nil: true }
  validates :access_level, inclusion: { in: Gitlab::Access.all_values }, presence: true
  validates :invite_email,
    presence: {
      if: :invite?
    },
    email: {
      allow_nil: true
    },
    uniqueness: {
      scope: [:source_type, :source_id],
      allow_nil: true
    }

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
      .where(requested_at: nil)
      .reorder(nil)
  end

  # Like active, but without invites. For when a User is required.
  scope :active_without_invites_and_requests, -> do
    left_join_users
      .where(users: { state: 'active' })
      .non_request
      .reorder(nil)
  end

  scope :invite, -> { where.not(invite_token: nil) }
  scope :non_invite, -> { where(invite_token: nil) }
  scope :request, -> { where.not(requested_at: nil) }
  scope :non_request, -> { where(requested_at: nil) }

  scope :has_access, -> { active.where('access_level > 0') }

  scope :guests, -> { active.where(access_level: GUEST) }
  scope :reporters, -> { active.where(access_level: REPORTER) }
  scope :developers, -> { active.where(access_level: DEVELOPER) }
  scope :masters,  -> { active.where(access_level: MASTER) }
  scope :owners,  -> { active.where(access_level: OWNER) }
  scope :owners_and_masters,  -> { active.where(access_level: [OWNER, MASTER]) }

  scope :order_name_asc, -> { left_join_users.reorder(Gitlab::Database.nulls_last_order('users.name', 'ASC')) }
  scope :order_name_desc, -> { left_join_users.reorder(Gitlab::Database.nulls_last_order('users.name', 'DESC')) }
  scope :order_recent_sign_in, -> { left_join_users.reorder(Gitlab::Database.nulls_last_order('users.last_sign_in_at', 'DESC')) }
  scope :order_oldest_sign_in, -> { left_join_users.reorder(Gitlab::Database.nulls_last_order('users.last_sign_in_at', 'ASC')) }

  before_validation :generate_invite_token, on: :create, if: -> (member) { member.invite_email.present? }

  after_create :send_invite, if: :invite?, unless: :importing?
  after_create :send_request, if: :request?, unless: :importing?
  after_create :create_notification_setting, unless: [:pending?, :importing?]
  after_create :post_create_hook, unless: [:pending?, :importing?]
  after_update :post_update_hook, unless: [:pending?, :importing?]
  after_destroy :destroy_notification_setting
  after_destroy :post_destroy_hook, unless: :pending?
  after_commit :refresh_member_authorized_projects

  default_value_for :notification_level, NotificationSetting.levels[:global]

  class << self
    def search(query)
      joins(:user).merge(User.search(query))
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

    def find_by_invite_token(invite_token)
      invite_token = Devise.token_generator.digest(self, :invite_token, invite_token)
      find_by(invite_token: invite_token)
    end

    def add_user(source, user, access_level, existing_members: nil, current_user: nil, expires_at: nil, ldap: false)
      # `user` can be either a User object, User ID or an email to be invited
      member = retrieve_member(source, user, existing_members)
      access_level = retrieve_access_level(access_level)

      return member unless can_update_member?(current_user, member)

      member.attributes = {
        created_by: member.created_by || current_user,
        access_level: access_level,
        expires_at: expires_at
      }

      if member.request?
        ::Members::ApproveAccessRequestService.new(
          current_user,
          access_level: access_level
        ).execute(
          member,
          skip_authorization: ldap,
          skip_log_audit_event: ldap
        )
      else
        member.save
      end

      member
    end

    def add_users(source, users, access_level, current_user: nil, expires_at: nil)
      return [] unless users.present?

      emails, users, existing_members = parse_users_list(source, users)

      self.transaction do
        (emails + users).map! do |user|
          add_user(
            source,
            user,
            access_level,
            existing_members: existing_members,
            current_user: current_user,
            expires_at: expires_at
          )
        end
      end
    end

    def access_levels
      Gitlab::Access.sym_options
    end

    private

    def parse_users_list(source, list)
      emails, user_ids, users = [], [], []
      existing_members = {}

      list.each do |item|
        case item
        when User
          users << item
        when Integer
          user_ids << item
        when /\A\d+\Z/
          user_ids << item.to_i
        when Devise.email_regexp
          emails << item
        end
      end

      if user_ids.present?
        users.concat(User.where(id: user_ids))
        existing_members = source.members_and_requesters.where(user_id: user_ids).index_by(&:user_id)
      end

      [emails, users, existing_members]
    end

    # This method is used to find users that have been entered into the "Add members" field.
    # These can be the User objects directly, their IDs, their emails, or new emails to be invited.
    def retrieve_user(user)
      return user if user.is_a?(User)

      User.find_by(id: user) || User.find_by(email: user) || user
    end

    def retrieve_member(source, user, existing_members)
      user = retrieve_user(user)

      if user.is_a?(User)
        if existing_members
          existing_members[user.id] || source.members.build(user_id: user.id)
        else
          source.members_and_requesters.find_or_initialize_by(user_id: user.id)
        end
      else
        source.members.build(invite_email: user)
      end
    end

    def retrieve_access_level(access_level)
      access_levels.fetch(access_level) { access_level.to_i }
    end

    def can_update_member?(current_user, member)
      # There is no current user for bulk actions, in which case anything is allowed
      !current_user || current_user.can?(:"update_#{member.type.underscore}", member)
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

  def accept_request
    return false unless request?

    updated = self.update(requested_at: nil)
    after_accept_request if updated

    updated
  end

  def accept_invite!(new_user)
    return false unless invite?

    self.invite_token = nil
    self.invite_accepted_at = Time.now.utc

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

  def create_notification_setting
    user.notification_settings.find_or_create_for(source)
  end

  def destroy_notification_setting
    notification_setting&.destroy
  end

  def notification_setting
    @notification_setting ||= user&.notification_settings_for(source)
  end

  def notifiable?(type, opts = {})
    # always notify when there isn't a user yet
    return true if user.blank?

    NotificationRecipientService.notifiable?(user, type, notifiable_options.merge(opts))
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
    # override in sub class
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
  def refresh_member_authorized_projects
    # If user/source is being destroyed, project access are going to be
    # destroyed eventually because of DB foreign keys, so we shouldn't bother
    # with refreshing after each member is destroyed through association
    return if destroyed_by_association.present?

    UserProjectAccessChangedService.new(user_id).execute
  end

  def after_accept_invite
    post_create_hook
  end

  def after_decline_invite
    # override in subclass
  end

  def after_accept_request
    post_create_hook
  end

  def system_hook_service
    SystemHooksService.new
  end

  def notification_service
    NotificationService.new
  end

  def notifiable_options
    {}
  end
end
