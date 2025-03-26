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

      value 'REPOSITORY_SIZE_ASC',  'Sort by total repository size, ascending order.', value: :repository_size_asc
      value 'REPOSITORY_SIZE_DESC', 'Sort by total repository size, descending order.', value: :repository_size_desc

      value 'SNIPPETS_SIZE_ASC',  'Sort by total snippet size, ascending order.', value: :snippets_size_asc
      value 'SNIPPETS_SIZE_DESC', 'Sort by total snippet size, descending order.', value: :snippets_size_desc

      value 'BUILD_ARTIFACTS_SIZE_ASC',  'Sort by total build artifact size, ascending order.',
        value: :build_artifacts_size_asc
      value 'BUILD_ARTIFACTS_SIZE_DESC', 'Sort by total build artifact size, descending order.',
        value: :build_artifacts_size_desc

      value 'LFS_OBJECTS_SIZE_ASC',  'Sort by total LFS object size, ascending order.', value: :lfs_objects_size_asc
      value 'LFS_OBJECTS_SIZE_DESC', 'Sort by total LFS object size, descending order.', value: :lfs_objects_size_desc

      value 'PACKAGES_SIZE_ASC',  'Sort by total package size, ascending order.', value: :packages_size_asc
      value 'PACKAGES_SIZE_DESC', 'Sort by total package size, descending order.', value: :packages_size_desc

      value 'WIKI_SIZE_ASC',  'Sort by total wiki size, ascending order.', value: :wiki_size_asc
      value 'WIKI_SIZE_DESC', 'Sort by total wiki size, descending order.', value: :wiki_size_desc

      value 'CONTAINER_REGISTRY_SIZE_ASC',  'Sort by total container registry size, ascending order.',
        value: :container_registry_size_asc
      value 'CONTAINER_REGISTRY_SIZE_DESC', 'Sort by total container registry size, descending order.',
        value: :container_registry_size_desc
    end
  end
end

Types::Projects::NamespaceProjectSortEnum.prepend_mod
