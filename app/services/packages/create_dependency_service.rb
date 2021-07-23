# frozen_string_literal: true
module Packages
  class CreateDependencyService < BaseService
    attr_reader :package, :dependencies

    def initialize(package, dependencies)
      @package = package
      @dependencies = dependencies
    end

    def execute
      Packages::DependencyLink.dependency_types.each_key do |type|
        create_dependency(type)
      end
    end

    private

    def create_dependency(type)
      return unless dependencies[type].is_a?(Hash)

      names_and_version_patterns = dependencies[type]
      existing_ids, existing_names = find_existing_ids_and_names(names_and_version_patterns)
      dependencies_to_insert = names_and_version_patterns

      if existing_names.any?
        dependencies_to_insert = names_and_version_patterns.reject { |k, _| k.in?(existing_names) }
      end

      ApplicationRecord.transaction do
        inserted_ids = bulk_insert_package_dependencies(dependencies_to_insert)
        bulk_insert_package_dependency_links(type, (existing_ids + inserted_ids))
      end
    end

    def find_existing_ids_and_names(names_and_version_patterns)
      ids_and_names = Packages::Dependency.for_package_names_and_version_patterns(names_and_version_patterns)
                                          .pluck_ids_and_names
      ids = ids_and_names.map(&:first) || []
      names = ids_and_names.map(&:second) || []
      [ids, names]
    end

    def bulk_insert_package_dependencies(names_and_version_patterns)
      return [] if names_and_version_patterns.empty?

      rows = names_and_version_patterns.map do |name, version_pattern|
        {
          name: name,
          version_pattern: version_pattern
        }
      end

      ids = database.bulk_insert(Packages::Dependency.table_name, rows, return_ids: true, on_conflict: :do_nothing)
      return ids if ids.size == names_and_version_patterns.size

      Packages::Dependency.uncached do
        # The bulk_insert statement above do not dirty the query cache. To make
        # sure that the results are fresh from the database and not from a stalled
        # and potentially wrong cache, this query has to be done with the query
        # chache disabled.
        Packages::Dependency.ids_for_package_names_and_version_patterns(names_and_version_patterns)
      end
    end

    def bulk_insert_package_dependency_links(type, dependency_ids)
      rows = dependency_ids.map do |dependency_id|
        {
          package_id: package.id,
          dependency_id: dependency_id,
          dependency_type: Packages::DependencyLink.dependency_types[type.to_s]
        }
      end

      database.bulk_insert(Packages::DependencyLink.table_name, rows)
    end

    def database
      ::Gitlab::Database
    end
  end
end
