# frozen_string_literal: true

module Types
  module CustomerRelations
    class ContactStateEnum < BaseEnum
      graphql_name 'CustomerRelationsContactState'

      value 'all',
        description: "All available contacts.",
        value: :all

      value 'active',
        description: "Active contacts.",
        value: :active

      value 'inactive',
        description: "Inactive contacts.",
        value: :inactive
    end
  end
end
