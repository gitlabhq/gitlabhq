# == Schema Information
#
# Table name: members
#
#  id                 :integer          not null, primary key
#  access_level       :integer          not null
#  source_id          :integer          not null
#  source_type        :string(255)      not null
#  user_id            :integer
#  notification_level :integer          not null
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  created_by_id      :integer
#  invite_email       :string(255)
#  invite_token       :string(255)
#  invite_accepted_at :datetime
#

class GroupMember < Member
  SOURCE_TYPE = 'Namespace'

  belongs_to :group, class_name: 'Group', foreign_key: 'source_id'

  # Make sure group member points only to group as it source
  default_value_for :source_type, SOURCE_TYPE
  default_value_for :notification_level, Notification::N_GLOBAL
  validates_format_of :source_type, with: /\ANamespace\z/
  default_scope { where(source_type: SOURCE_TYPE) }

  scope :with_group, ->(group) { where(source_id: group.id) }
  scope :with_user, ->(user) { where(user_id: user.id) }

  def self.access_level_roles
    Gitlab::Access.options_with_owner
  end

  def group
    source
  end

  def access_field
    access_level
  end

  private

  def send_invite
    notification_service.invite_group_member(self, @raw_invite_token)

    super
  end

  def post_create_hook
    notification_service.new_group_member(self)

    super
  end

  def post_update_hook
    if access_level_changed?
      notification_service.update_group_member(self)
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
