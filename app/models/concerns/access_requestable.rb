# frozen_string_literal: true

# == AccessRequestable concern
#
# Contains functionality related to objects that can receive request for access.
#
# Used by Project, and Group.
#
module AccessRequestable
  extend ActiveSupport::Concern

  def request_access(user)
    Members::RequestAccessService.new(user).execute(self)
  end
end
