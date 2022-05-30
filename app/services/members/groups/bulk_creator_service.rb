# frozen_string_literal: true

module Members
  module Groups
    class BulkCreatorService < Members::Groups::CreatorService
      include Members::BulkCreateUsers

      class << self
        def cannot_manage_owners?(source, current_user)
          source.max_member_access_for_user(current_user) < Gitlab::Access::OWNER
        end
      end
    end
  end
end
