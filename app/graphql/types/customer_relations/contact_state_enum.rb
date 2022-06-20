# frozen_string_literal: true

module Types
  module CustomerRelations
    class ContactStateEnum < BaseEnum
      graphql_name 'CustomerRelationsContactState'

      value 'active',
            description: "Active contact.",
            value: :active

      value 'inactive',
            description: "Inactive contact.",
            value: :inactive
    end
  end
end
