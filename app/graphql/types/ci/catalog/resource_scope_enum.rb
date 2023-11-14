# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      class ResourceScopeEnum < BaseEnum
        graphql_name 'CiCatalogResourceScope'
        description 'Values for scoping catalog resources'

        value 'ALL', 'All catalog resources visible to the current user.', value: :all
      end
    end
  end
end
