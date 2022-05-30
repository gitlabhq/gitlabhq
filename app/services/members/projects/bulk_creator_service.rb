# frozen_string_literal: true

module Members
  module Projects
    class BulkCreatorService < Members::Projects::CreatorService
      include Members::BulkCreateUsers

      class << self
        def cannot_manage_owners?(source, current_user)
          !Ability.allowed?(current_user, :manage_owners, source)
        end
      end
    end
  end
end
