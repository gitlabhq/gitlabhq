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
      user: user,
      requested_at: Time.now.utc)
  end
end
