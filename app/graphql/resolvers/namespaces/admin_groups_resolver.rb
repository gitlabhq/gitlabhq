# frozen_string_literal: true

module Resolvers
  module Namespaces
    class AdminGroupsResolver < BaseGroupsResolver
      description 'Find groups visible to the current admin.'

      type Types::Namespaces::GroupInterface.connection_type, null: true
    end
  end
end
