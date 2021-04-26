# frozen_string_literal: true

module Types
  module Packages
    class PackageGroupSortEnum < PackageSortEnum
      graphql_name 'PackageGroupSort'
      description 'Values for sorting group packages'

      # The following enums are not available till we enable the new Arel node:
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58657#note_552632305
      # value 'PROJECT_PATH_DESC', 'Project by descending order.', value: :project_path_desc
      # value 'PROJECT_PATH_ASC', 'Project by ascending order.', value: :project_path_asc
    end
  end
end
