# frozen_string_literal: true

module Mutations
  module Issues
    module CommonMutationArguments
      extend ActiveSupport::Concern

      included do
        argument :description, GraphQL::Types::String,
          required: false,
          description: copy_field_description(Types::IssueType, :description)

        argument :due_date, GraphQL::Types::ISO8601Date,
          required: false,
          description: copy_field_description(Types::IssueType, :due_date)

        argument :confidential, GraphQL::Types::Boolean,
          required: false,
          description: copy_field_description(Types::IssueType, :confidential)

        argument :locked, GraphQL::Types::Boolean,
          as: :discussion_locked,
          required: false,
          description: copy_field_description(Types::IssueType, :discussion_locked)

        argument :type, Types::IssueTypeEnum,
          as: :issue_type,
          required: false,
          description: copy_field_description(Types::IssueType, :type)
      end
    end
  end
end
