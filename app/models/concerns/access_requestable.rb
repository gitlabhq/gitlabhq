# == AccessRequestable concern
#
# Contains functionality related to objects that can receive request for access.
#
# Used by Project, and Group.
#
module AccessRequestable
  extend ActiveSupport::Concern

  def request_access(user)
    members.create(
      access_level: Gitlab::Access::DEVELOPER,
      created_by: user,
      requested_at: Time.now.utc)
  end

  def access_requested?(user)
    members.where(created_by_id: user.id).where.not(requested_at: nil).any?
  end

  private

  # Returns a `<entities>_members` association, e.g.: project_members, group_members
  def members
    @members ||= send("#{self.class.to_s.underscore}_members".to_sym)
  end
end
