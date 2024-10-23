# frozen_string_literal: true

module Types
  module WorkItems
    class EmailParticipantType < BaseObject
      graphql_name 'EmailParticipantType'

      # Don't use read_external_emails here, because we obfuscate emails instead.
      authorize :read_work_item

      present_using IssueEmailParticipantPresenter

      field :email, GraphQL::Types::String,
        description: 'Email address of the email participant. For guests, the email address is obfuscated.', null: false
    end
  end
end
