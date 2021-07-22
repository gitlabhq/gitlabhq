# frozen_string_literal: true

module Mutations
  module Notes
    module Update
      class Note < Mutations::Notes::Update::Base
        graphql_name 'UpdateNote'
        description "Updates a Note.\n#{QUICK_ACTION_ONLY_WARNING}"

        argument :body,
                 GraphQL::Types::String,
                 required: false,
                 description: copy_field_description(Types::Notes::NoteType, :body)

        argument :confidential,
                 GraphQL::Types::Boolean,
                 required: false,
                 description: 'The confidentiality flag of a note. Default is false.'

        private

        def pre_update_checks!(_note, _args)
          # no-op
        end
      end
    end
  end
end
