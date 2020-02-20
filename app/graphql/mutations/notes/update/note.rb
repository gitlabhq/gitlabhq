# frozen_string_literal: true

module Mutations
  module Notes
    module Update
      class Note < Mutations::Notes::Update::Base
        graphql_name 'UpdateNote'

        argument :body,
                  GraphQL::STRING_TYPE,
                  required: true,
                  description: copy_field_description(Types::Notes::NoteType, :body)

        private

        def pre_update_checks!(note, _args)
          check_object_is_note!(note)
        end
      end
    end
  end
end
