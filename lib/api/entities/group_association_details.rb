# frozen_string_literal: true

module API
  module Entities
    class GroupAssociationDetails < Entities::BasicGroupDetails
      expose :parent_id, documentation: { type: 'Integer', format: 'int64', example: 1 }
      expose :organization_id, documentation: { type: 'Integer', format: 'int64', example: 1 }

      # rubocop:disable API/AccessLevelStringType -- Introduced before the cop
      expose :access_levels, documentation: { type: 'Integer', example: 50 } do |group, options|
        group.highest_group_member(options[:current_user])&.access_level
      end
      # rubocop:enable API/AccessLevelStringType

      expose :visibility, documentation: { type: 'String', example: 'public' }
    end
  end
end
