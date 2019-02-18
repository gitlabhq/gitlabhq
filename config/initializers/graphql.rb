# frozen_string_literal: true

GraphQL::Field.accepts_definitions(authorize: GraphQL::Define.assign_metadata_key(:authorize))
Types::BaseField.accepts_definition(:authorize)
