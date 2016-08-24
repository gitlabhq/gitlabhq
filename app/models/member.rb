class Member < ActiveRecord::Base
  include Sortable
  include Importable
  include Expirable
  include Gitlab::Access

  attr_accessor :raw_invite_token
  attr_accessor :skip_notification

  belongs_to :created_by, class_name: "User"
  belongs_to :user
  belongs_to :source, polymorphic: true

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

  scope :invite, -> { where.not(invite_token: nil) }
  scope :non_invite, -> { where(invite_token: nil) }
  scope :request, -> { where.not(requested_at: nil) }
  scope :has_access, -> { where('access_level > 0') }

  scope :guests, -> { where(access_level: GUEST) }
  scope :reporters, -> { where(access_level: REPORTER) }
  scope :developers, -> { where(access_level: DEVELOPER) }
  scope :masters,  -> { where(access_level: MASTER) }
  scope :owners,  -> { where(access_level: OWNER) }
  scope :owners_and_masters,  -> { where(access_level: [OWNER, MASTER]) }

  before_validation :generate_invite_token, on: :create, if: -> (member) { member.invite_email.present? }

  after_create :send_invite, if: :invite?, unless: :importing?
  after_create :send_request, if: :request?, unless: :importing?
  after_create :create_notification_setting, unless: [:pending?, :importing?]
  after_create :post_create_hook, unless: [:pending?, :importing?]
  after_update :post_update_hook, unless: [:pending?, :importing?]
  after_destroy :post_destroy_hook, unless: :pending?

  delegate :name, :username, :email, to: :user, prefix: true

  default_value_for :notification_level, NotificationSetting.levels[:global]

  class << self
    def access_for_user_ids(user_ids)
      where(user_id: user_ids).has_access.pluck(:user_id, :access_level).to_h
    end

    def find_by_invite_token(invite_token)
      invite_token = Devise.token_generator.digest(self, :invite_token, invite_token)
      find_by(invite_token: invite_token)
    end

    # This method is used to find users that have been entered into the "Add members" field.
    # These can be the User objects directly, their IDs, their emails, or new emails to be invited.
    def user_for_id(user_id)
      return user_id if user_id.is_a?(User)

      user = User.find_by(id: user_id)
      user ||= User.find_by(email: user_id)
      user ||= user_id
      user
    end

    def add_user(members, user_id, access_level, current_user: nil, skip_notification: false, expires_at: nil)
      user = user_for_id(user_id)

      # `user` can be either a User object or an email to be invited
      if user.is_a?(User)
        member = members.find_or_initialize_by(user_id: user.id)
      else
        member = members.build
        member.invite_email = user
      end

      if can_update_member?(current_user, member) || project_creator?(member, access_level)
        member.created_by ||= current_user
        member.access_level = access_level
        member.expires_at = expires_at
        member.skip_notification = skip_notification

        member.save
      end
    end

    private

    def can_update_member?(current_user, member)
      # There is no current user for bulk actions, in which case anything is allowed
      !current_user ||
        current_user.can?(:update_group_member, member) ||
        current_user.can?(:update_project_member, member)
    end

    def project_creator?(member, access_level)
      member.new_record? && member.owner? &&
        access_level.to_i == ProjectMember::MASTER
    end
  end

  def real_source_type
    source_type
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

  def notification_setting
    @notification_setting ||= user.notification_settings_for(source)
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
    # override in subclass
  end

  def post_destroy_hook
    system_hook_service.execute_hooks_for(self, :destroy)
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
end
