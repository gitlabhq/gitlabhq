# frozen_string_literal: true

module Types
  module Projects
    class NamespaceProjectSortEnum < BaseEnum
      graphql_name 'NamespaceProjectSort'
      description 'Values for sorting projects'

      value 'SIMILARITY', 'Most similar to the search query.', value: :similarity
      value 'ACTIVITY_DESC', 'Sort by latest activity, descending order.', value: :latest_activity_desc
      value 'STORAGE_SIZE_ASC',  'Sort by total storage size, ascending order.', value: :storage_size_asc
      value 'STORAGE_SIZE_DESC', 'Sort by total storage size, descending order.', value: :storage_size_desc
    end
  end
end

Types::Projects::NamespaceProjectSortEnum.prepend_mod
