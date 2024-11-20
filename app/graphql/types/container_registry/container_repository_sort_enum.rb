# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositorySortEnum < SortEnum
      graphql_name 'ContainerRepositorySort'
      description 'Values for sorting container repositories'

      value 'NAME_ASC', 'Name by ascending order.', value: :name_asc
      value 'NAME_DESC', 'Name by descending order.', value: :name_desc
    end
  end
end
