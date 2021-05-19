# frozen_string_literal: true

module Types
  module Packages
    class PackageSortEnum < BaseEnum
      graphql_name 'PackageSort'
      description 'Values for sorting package'

      value 'CREATED_DESC', 'Ordered by created_at in descending order.', value: :created_desc
      value 'CREATED_ASC', 'Ordered by created_at in ascending order.', value: :created_asc
      value 'NAME_DESC', 'Ordered by name in descending order.', value: :name_desc
      value 'NAME_ASC', 'Ordered by name in ascending order.', value: :name_asc
      value 'VERSION_DESC', 'Ordered by version in descending order.', value: :version_desc
      value 'VERSION_ASC', 'Ordered by version in ascending order.', value: :version_asc
      value 'TYPE_DESC', 'Ordered by type in descending order.', value: :type_desc
      value 'TYPE_ASC', 'Ordered by type in ascending order.', value: :type_asc
    end
  end
end
