# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationUserTypeEnum < BaseEnum
      graphql_name 'OrganizationUserType'
      description 'Type of an organization user'

      value 'USER',
        value: :default,
        description: 'Regular organization user.',
        experiment: { milestone: '19.3' }
      value 'ADMIN',
        value: :owner,
        description: 'Organization administrator.',
        experiment: { milestone: '19.3' }
    end
  end
end
