# frozen_string_literal: true

module Members
  module Groups
    class BulkCreatorService < Members::Groups::CreatorService
      include Members::BulkCreateUsers
    end
  end
end
