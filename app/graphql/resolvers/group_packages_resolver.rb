# frozen_string_literal: true

module Resolvers
  class GroupPackagesResolver < BaseResolver
    type Types::Packages::PackageType.connection_type, null: true

    argument :sort, Types::Packages::PackageGroupSortEnum,
      description: 'Sort packages by this criteria.',
      required: false,
      default_value: :created_desc

    SORT_TO_PARAMS_MAP = {
      created_desc: { order_by: 'created', sort: 'desc' },
      created_asc: { order_by: 'created', sort: 'asc' },
      name_desc: { order_by: 'name', sort: 'desc' },
      name_asc: { order_by: 'name', sort: 'asc' },
      version_desc: { order_by: 'version', sort: 'desc' },
      version_asc: { order_by: 'version', sort: 'asc' },
      type_desc: { order_by: 'type', sort: 'desc' },
      type_asc: { order_by: 'type', sort: 'asc' },
      project_path_desc: { order_by: 'project_path', sort: 'desc' },
      project_path_asc: { order_by: 'project_path', sort: 'asc' }
    }.freeze

    def ready?(**args)
      context[self.class] ||= { executions: 0 }
      context[self.class][:executions] += 1
      raise GraphQL::ExecutionError, "Packages can be requested only for one group at a time" if context[self.class][:executions] > 1

      super
    end

    def resolve(sort:)
      return unless packages_available?

      ::Packages::GroupPackagesFinder.new(current_user, object, SORT_TO_PARAMS_MAP[sort]).execute
    end

    private

    def packages_available?
      ::Gitlab.config.packages.enabled
    end
  end
end
