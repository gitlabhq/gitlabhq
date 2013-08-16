# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string(255)
#  description :string(255)      default(""), not null
#

class Group < Namespace
  has_many :users_groups, dependent: :destroy
  has_many :users, through: :users_groups

  after_create :add_owner

  def human_name
    name
  end

  def owners
    @owners ||= (users_groups.owners.map(&:user) << owner)
  end

  def add_users(user_ids, group_access)
    user_ids.compact.each do |user_id|
      self.users_groups.create(user_id: user_id, group_access: group_access)
    end
  end

  def change_owner(user)
    self.owner = user
    membership = users_groups.where(user_id: user.id).first

    if membership
      membership.update_attributes(group_access: UsersGroup::OWNER)
    else
      add_owner
    end
  end

  private

  def add_owner
    self.add_users([owner.id], UsersGroup::OWNER)
  end
end
