class GroupMember < Member
  SOURCE_TYPE = 'Namespace'.freeze

  belongs_to :group, foreign_key: 'source_id'

  delegate :update_two_factor_requirement, to: :user

  # Make sure group member points only to group as it source
  default_value_for :source_type, SOURCE_TYPE
  validates :source_type, format: { with: /\ANamespace\z/ }
  default_scope { where(source_type: SOURCE_TYPE) }

  after_create :update_two_factor_requirement, unless: :invite?
  after_destroy :update_two_factor_requirement, unless: :invite?

  def self.access_level_roles
    Gitlab::Access.options_with_owner
  end

  def self.access_levels
    Gitlab::Access.sym_options_with_owner
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

  def send_invite
    run_after_commit_or_now { notification_service.invite_group_member(self, @raw_invite_token) }

    super
  end

  def post_create_hook
    run_after_commit_or_now { notification_service.new_group_member(self) }

    super
  end

  def post_update_hook
    if access_level_changed?
      run_after_commit { notification_service.update_group_member(self) }
    end

    super
  end

  def after_accept_invite
    notification_service.accept_group_invite(self)

    super
  end

  def after_decline_invite
    notification_service.decline_group_invite(self)

    super
  end
end
