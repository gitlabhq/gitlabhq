# frozen_string_literal: true

module API
  module Entities
    class GroupAssociationDetails < Entities::BasicGroupDetails
      expose :parent_id
      expose :organization_id

      expose :access_levels do |group, options|
        group.highest_group_member(options[:current_user])&.access_level
      end

      expose :visibility, documentation: { type: 'string', example: 'public' }
    end
  end
end
