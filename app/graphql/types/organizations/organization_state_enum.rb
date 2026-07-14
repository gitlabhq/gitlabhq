# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationStateEnum < BaseEnum
      graphql_name 'OrganizationState'
      description 'State of an organization.'

      ::Organizations::Organization.states.each_key do |state|
        milestone = ::Organizations::Stateful::READ_ONLY_STATES.include?(state.to_sym) ? '19.2' : '19.0'

        value state.upcase, value: state,
          description: "#{state.titleize} organization.",
          experiment: { milestone: milestone }
      end
    end
  end
end
