# frozen_string_literal: true

module Types
  class CommitActionType < BaseInputObject
    argument :action, type: Types::CommitActionModeEnum, required: true,
      description: 'Action to perform: create, delete, move, update, or chmod.'
    argument :content, type: GraphQL::Types::String, required: false,
      description: 'Content of the file.'
    argument :encoding, type: Types::CommitEncodingEnum, required: false,
      description: 'Encoding of the file. Default is text.'
    argument :execute_filemode, type: GraphQL::Types::Boolean, required: false,
      description: 'Enables/disables the execute flag on the file.'
    argument :file_path, type: GraphQL::Types::String, required: true,
      description: 'Full path to the file.'
    argument :last_commit_id, type: GraphQL::Types::String, required: false,
      description: 'Last known file commit ID.'
    argument :previous_path, type: GraphQL::Types::String, required: false,
      description: 'Original full path to the file being moved.'
  end
end
