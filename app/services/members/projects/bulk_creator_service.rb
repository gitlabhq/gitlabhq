# frozen_string_literal: true

module Members
  module Projects
    class BulkCreatorService < Members::Projects::CreatorService
      include Members::BulkCreateUsers
    end
  end
end
