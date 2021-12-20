# frozen_string_literal: true

module Types
  class ContainerRepositoryTagsSortEnum < BaseEnum
    graphql_name 'ContainerRepositoryTagSort'
    description 'Values for sorting tags'

    value 'NAME_ASC', 'Ordered by name in ascending order.', value: :name_asc
    value 'NAME_DESC', 'Ordered by name in descending order.', value: :name_desc
  end
end
