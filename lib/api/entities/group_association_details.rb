# frozen_string_literal: true

module API
  module Entities
    class GroupAssociationDetails < Entities::BasicGroupDetails
      expose :parent_id, documentation: { type: 'Integer', example: 1 }
      expose :organization_id, documentation: { type: 'Integer', example: 1 }

      expose :access_levels, documentation: { type: 'Integer', example: 50 } do |group, options|
        group.highest_group_member(options[:current_user])&.access_level
      end

      expose :visibility, documentation: { type: 'String', example: 'public' }
    end
  end
end
