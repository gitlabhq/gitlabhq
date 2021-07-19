# frozen_string_literal: true

class GroupMember < Member
  include FromUnion
  include CreatedAtFilterable

  SOURCE_TYPE = 'Namespace'

  belongs_to :group, foreign_key: 'source_id'
  alias_attribute :namespace_id, :source_id
  delegate :update_two_factor_requirement, to: :user, allow_nil: true

  # Make sure group member points only to group as it source
  default_value_for :source_type, SOURCE_TYPE
  validates :source_type, format: { with: /\ANamespace\z/ }
  validates :access_level, presence: true
  validate :access_level_inclusion

  default_scope { where(source_type: SOURCE_TYPE) } # rubocop:disable Cop/DefaultScope

  scope :of_groups, ->(groups) { where(source_id: groups.select(:id)) }
  scope :of_ldap_type, -> { where(ldap: true) }
  scope :count_users_by_group_id, -> { group(:source_id).count }
  scope :with_user, -> (user) { where(user: user) }

  after_create :update_two_factor_requirement, unless: :invite?
  after_destroy :update_two_factor_requirement, unless: :invite?

  attr_accessor :last_owner, :last_blocked_owner

  self.enumerate_columns_in_select_statements = true

  def self.access_level_roles
    Gitlab::Access.options_with_owner
  end

  def self.pluck_user_ids
    pluck(:user_id)
  end

  def group
    source
  end

  # Because source_type is `Namespace`...
  def real_source_type
    'Group'
  end

  def notifiable_options
    { group: group }
  end

  private

  def access_level_inclusion
    return if access_level.in?(Gitlab::Access.all_values)

    errors.add(:access_level, "is not included in the list")
  end

  def send_invite
    run_after_commit_or_now { notification_service.invite_group_member(self, @raw_invite_token) }

    super
  end

  def post_create_hook
    if send_welcome_email?
      run_after_commit_or_now { notification_service.new_group_member(self) }
    end

    super
  end

  def post_update_hook
    if saved_change_to_access_level?
      run_after_commit { notification_service.update_group_member(self) }
    end

    if saved_change_to_expires_at?
      run_after_commit { notification_service.updated_group_member_expiration(self) }
    end

    super
  end

  def after_accept_invite
    notification_service.accept_group_invite(self)
    update_two_factor_requirement

    super
  end

  def after_decline_invite
    notification_service.decline_group_invite(self)

    super
  end

  def send_welcome_email?
    true
  end
end

GroupMember.prepend_mod_with('GroupMember')
