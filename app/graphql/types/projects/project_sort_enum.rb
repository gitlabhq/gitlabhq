# frozen_string_literal: true

module Types
  module Projects
    class ProjectSortEnum < SortEnum
      graphql_name 'ProjectSort'
      description 'Values for sorting projects'

      value 'ID_ASC', 'ID by ascending order.', value: :id_asc
      value 'ID_DESC', 'ID by descending order.', value: :id_desc
      value 'LATEST_ACTIVITY_ASC', 'Latest activity by ascending order.', value: :latest_activity_asc
      value 'LATEST_ACTIVITY_DESC', 'Latest activity by descending order.', value: :latest_activity_desc
      value 'NAME_ASC', 'Name by ascending order.', value: :name_asc
      value 'NAME_DESC', 'Name by descending order.', value: :name_desc
      value 'PATH_ASC', 'Path by ascending order.', value: :path_asc
      value 'PATH_DESC', 'Path by descending order.', value: :path_desc
      value 'STARS_ASC', 'Stars by ascending order.', value: :stars_asc
      value 'STARS_DESC', 'Stars by descending order.', value: :stars_desc
      value 'STORAGE_SIZE_ASC', 'Storage size by ascending order.', value: :storage_size_asc
      value 'STORAGE_SIZE_DESC', 'Storage size by descending order.', value: :storage_size_desc
    end
  end
end
