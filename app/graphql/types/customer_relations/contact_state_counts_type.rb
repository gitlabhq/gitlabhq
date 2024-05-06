# frozen_string_literal: true

module Types
  module CustomerRelations
    class ContactStateCountsType < Types::BaseObject
      graphql_name 'ContactStateCounts'
      description 'Represents the total number of contacts for the represented states.'

      authorize :read_crm_contact

      def self.available_contact_states
        @available_contact_states ||= ::CustomerRelations::Contact.states.keys.push('all')
      end

      available_contact_states.each do |state|
        field state,
          GraphQL::Types::Int,
          null: true,
          description: "Number of contacts with state `#{state.upcase}`"
      end
    end
  end
end
