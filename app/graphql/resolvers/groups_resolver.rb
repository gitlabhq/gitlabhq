# frozen_string_literal: true

module Resolvers
  class GroupsResolver < Namespaces::BaseGroupsResolver
    description 'Find groups visible to the current user.'

    type Types::GroupType.connection_type, null: true
  end
end

Resolvers::GroupsResolver.prepend_mod_with('Resolvers::GroupsResolver')
