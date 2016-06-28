class GroupMember < Member
  SOURCE_TYPE = 'Namespace'

  belongs_to :group, class_name: 'Group', foreign_key: 'source_id'

  # Make sure group member points only to group as it source
  default_value_for :source_type, SOURCE_TYPE
  validates_format_of :source_type, with: /\ANamespace\z/
  default_scope { where(source_type: SOURCE_TYPE) }

  scope :with_ldap_dn, -> { joins(user: :identities).where("identities.provider LIKE ?", 'ldap%') }
  scope :select_access_level_and_user, -> { select(:access_level, :user_id) }
  scope :with_identity_provider, ->(provider) do
    joins(user: :identities).where(identities: { provider: provider })
  end

  def self.access_level_roles
    Gitlab::Access.options_with_owner
  end

  def group
    source
  end

  def access_field
    access_level
  end

  # Because source_type is `Namespace`...
  def real_source_type
    'Group'
  end

  private

  def send_invite
    notification_service.invite_group_member(self, @raw_invite_token) unless @skip_notification

    super
  end

  def post_create_hook
    notification_service.new_group_member(self) unless @skip_notification

    super
  end

  def post_update_hook
    if access_level_changed?
      notification_service.update_group_member(self) unless @skip_notification
    end

    super
  end

  def after_accept_invite
    notification_service.accept_group_invite(self) unless @skip_notification

    super
  end

  def after_decline_invite
    notification_service.decline_group_invite(self) unless @skip_notification

    super
  end
end
