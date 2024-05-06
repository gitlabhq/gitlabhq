# frozen_string_literal: true

module Types
  module CustomerRelations
    class OrganizationStateEnum < BaseEnum
      graphql_name 'CustomerRelationsOrganizationState'

      value 'all',
        description: "All available organizations.",
        value: :all

      value 'active',
        description: "Active organizations.",
        value: :active

      value 'inactive',
        description: "Inactive organizations.",
        value: :inactive
    end
  end
end
