# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#  type        :string(255)
#  description :string(255)      default(""), not null
#  avatar      :string(255)
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Group < Namespace
  has_many :users_groups, dependent: :destroy
  has_many :users, through: :users_groups

  validate :avatar_type, if: ->(user) { user.avatar_changed? }
  validates :avatar, file_size: { maximum: 100.kilobytes.to_i }

  mount_uploader :avatar, AttachmentUploader

  def human_name
    name
  end

  def owners
    @owners ||= users_groups.owners.map(&:user)
  end

  def add_users(user_ids, group_access)
    user_ids.compact.each do |user_id|
      user = self.users_groups.find_or_initialize_by(user_id: user_id)
      user.update_attributes(group_access: group_access)
    end
  end

  def add_user(user, group_access)
    self.users_groups.create(user_id: user.id, group_access: group_access)
  end

  def add_owner(user)
    self.add_user(user, UsersGroup::OWNER)
  end

  def has_owner?(user)
    owners.include?(user)
  end

  def has_master?(user)
    members.masters.where(user_id: user).any?
  end

  def last_owner?(user)
    has_owner?(user) && owners.size == 1
  end

  def members
    users_groups
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, "only images allowed"
    end
  end

  def public_profile?
    projects.public_only.any?
  end
end
