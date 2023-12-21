# frozen_string_literal: true

module Resolvers
  class GroupResolver < BaseResolver
    def self.target_type
      'group'
    end

    include FullPathResolver

    type Types::GroupType, null: true

    def resolve(full_path:)
      model_by_full_path(Group, full_path)
    end
  end
end
