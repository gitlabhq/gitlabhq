# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationStateEnum < BaseEnum
      graphql_name 'OrganizationState'
      description 'State of an organization.'

      ::Organizations::Organization.states.each_key do |state|
        value state.upcase, value: state,
          description: "#{state.titleize} organization.",
          experiment: { milestone: '19.0' }
      end
    end
  end
end
