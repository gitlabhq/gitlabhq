# frozen_string_literal: true

module Types
  module Import
    class SourceUserStatusEnum < BaseEnum
      graphql_name 'ImportSourceUserStatus'

      ::Import::SourceUser.state_machines[:status].states.each do |state|
        value state.name.upcase,
          description: "An import source user mapping that is #{state.human_name}.",
          value: state.value
      end
    end
  end
end
