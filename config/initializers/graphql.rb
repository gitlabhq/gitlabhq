# frozen_string_literal: true

GraphQL::ObjectType.accepts_definitions(authorize: GraphQL::Define.assign_metadata_key(:authorize))

GraphQL::Schema::Object.accepts_definition(:authorize)
