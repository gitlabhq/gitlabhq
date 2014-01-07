# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string(255)
#  description :string(255)      default(""), not null
#

class Group < Namespace
  has_many :users_groups, dependent: :destroy
  has_many :users, through: :users_groups

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

  def last_owner?(user)
    has_owner?(user) && owners.size == 1
  end

  def members
    users_groups
  end
end
