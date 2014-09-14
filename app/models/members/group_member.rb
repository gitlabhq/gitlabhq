class GroupMember < Member
  SOURCE_TYPE = 'Group'

  belongs_to :group, class_name: 'Group', foreign_key: 'source_id'

  # Make sure group member points only to group as it source
  default_value_for :source_type, SOURCE_TYPE
  validates_format_of :source_type, with: /\AGroup\z/
  default_scope { where(source_type: SOURCE_TYPE) }

  scope :with_group, ->(group) { where(source_id: group.id) }
  scope :with_user, ->(user) { where(user_id: user.id) }

  after_create :notify_create
  after_update :notify_update

  def self.access_level_roles
    Gitlab::Access.options_with_owner
  end

  def group
    source
  end

  def access_field
    access_level
  end

  def notify_create
    notification_service.new_group_member(self)
  end

  def notify_update
    if access_level_changed?
      notification_service.update_group_member(self)
    end
  end

  def notification_service
    NotificationService.new
  end
end
