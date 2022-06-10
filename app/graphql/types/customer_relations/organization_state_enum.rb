# frozen_string_literal: true

module Types
  module CustomerRelations
    class OrganizationStateEnum < BaseEnum
      graphql_name 'CustomerRelationsOrganizationState'

      value 'active',
            description: "Active organization.",
            value: :active

      value 'inactive',
            description: "Inactive organization.",
            value: :inactive
    end
  end
end
