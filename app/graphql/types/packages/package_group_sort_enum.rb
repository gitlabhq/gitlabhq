# frozen_string_literal: true

module Types
  module Packages
    class PackageGroupSortEnum < PackageSortEnum
      graphql_name 'PackageGroupSort'
      description 'Values for sorting group packages'

      value 'PROJECT_PATH_DESC', 'Ordered by project path in descending order.', value: :project_path_desc
      value 'PROJECT_PATH_ASC', 'Ordered by project path in ascending order.', value: :project_path_asc
    end
  end
end
