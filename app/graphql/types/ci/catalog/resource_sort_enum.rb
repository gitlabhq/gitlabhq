# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      class ResourceSortEnum < BaseEnum
        graphql_name 'CiCatalogResourceSort'
        description 'Values for sorting catalog resources'

        value 'NAME_ASC', 'Name by ascending order.', value: :name_asc
        value 'NAME_DESC', 'Name by descending order.', value: :name_desc
        value 'LATEST_RELEASED_AT_ASC', 'Latest release date by ascending order.', value: :latest_released_at_asc
        value 'LATEST_RELEASED_AT_DESC', 'Latest release date by descending order.', value: :latest_released_at_desc
        value 'CREATED_ASC', 'Created date by ascending order.', value: :created_at_asc
        value 'CREATED_DESC', 'Created date by descending order.', value: :created_at_desc
        value 'STAR_COUNT_ASC', 'Star count by ascending order.', value: :star_count_asc
        value 'STAR_COUNT_DESC', 'Star count by descending order.', value: :star_count_desc
        value 'USAGE_COUNT_ASC', 'Last 30-day usage count by ascending order.', value: :usage_count_asc
        value 'USAGE_COUNT_DESC', 'Last 30-day usage count by descending order.', value: :usage_count_desc
      end
    end
  end
end
