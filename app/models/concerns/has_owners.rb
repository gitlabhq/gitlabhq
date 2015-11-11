# == Owners concern
#
# Contains owners functionality for groups
#
module HasOwners
  extend ActiveSupport::Concern

  def owners
    @owners ||= members.owners.includes(:user).map(&:user)
  end

  def members
    raise NotImplementedError, "Expected my_members to be defined in #{self.class.name}"
  end

  def add_owner(user, current_user = nil)
    add_user(user, Gitlab::Access::OWNER, current_user)
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
end
