# frozen_string_literal: true

module Resolvers
  class PackagesBaseResolver < BaseResolver
    type Types::Packages::PackageType.connection_type, null: true

    argument :sort, Types::Packages::PackageSortEnum,
        description: 'Sort packages by this criteria.',
        required: false,
        default_value: :created_desc

    argument :package_name, GraphQL::STRING_TYPE,
        description: 'Search a package by name.',
        required: false,
        default_value: nil

    argument :package_type, Types::Packages::PackageTypeEnum,
        description: 'Filter a package by type.',
        required: false,
        default_value: nil

    argument :status, Types::Packages::PackageStatusEnum,
        description: 'Filter a package by status.',
        required: false,
        default_value: nil

    argument :include_versionless, GraphQL::BOOLEAN_TYPE,
        description: 'Include versionless packages.',
        required: false,
        default_value: false

    SORT_TO_PARAMS_MAP = {
      created_desc: { order_by: 'created', sort: 'desc' },
      created_asc: { order_by: 'created', sort: 'asc' },
      name_desc: { order_by: 'name', sort: 'desc' },
      name_asc: { order_by: 'name', sort: 'asc' },
      version_desc: { order_by: 'version', sort: 'desc' },
      version_asc: { order_by: 'version', sort: 'asc' },
      type_desc: { order_by: 'type', sort: 'desc' },
      type_asc: { order_by: 'type', sort: 'asc' }
    }.freeze

    def resolve
      raise NotImplementedError
    end

    private

    def packages_available?
      ::Gitlab.config.packages.enabled
    end
  end
end
