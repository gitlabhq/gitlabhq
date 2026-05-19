# frozen_string_literal: true

module WorkItems
  class TypesFinder
    def initialize(container:)
      @container = container
    end

    # `only_available` uses a `nil` sentinel default to distinguish three cases:
    #   - `nil`   => caller did not pass the argument at all (new default behaviour).
    #               Returns all types for the namespace with FF/license filters
    #               applied via the provider's `available_types`. This is the path the
    #               GraphQL resolver uses when the FE drops the deprecated
    #               `onlyAvailable` argument.
    #   - `true`  => legacy "only available" path. Returns `allowed_types` (which
    #               keeps the `project_namespace?` guard for backward
    #               compatibility with the legacy `WorkItems::TypesFilter`).
    #   - `false` => legacy "all types" path. Returns the unfiltered list
    #               (`all_ordered_by_name`), preserving behaviour for any caller
    #               that explicitly opts out of filtering.
    #
    # TODO: The `name` and `only_available` parameters are deprecated and will be removed in 19.1.
    # At that point the three branches collapse into a single call to
    # `available_types` (which will be merged with `allowed_types`).
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/593038
    def execute(name: nil, only_available: nil)
      return [] if unavailable_container?

      # The provider now returns both system-defined and custom work item types when the
      # work_item_configurable_types feature flag is enabled. When disabled, it falls back
      # to system-defined types only for backward compatibility.
      provider = ::WorkItems::TypesFramework::Provider.new(@container)

      # Default ("omitted") path: return all types filtered by FF/license.
      return filter_by_name(provider.available_types, name) if only_available.nil?

      # Legacy `only_available: false` path: return everything unfiltered.
      if only_available == false
        return Array.wrap(provider.find_by_base_type(name)) if name.present?

        return provider.all_ordered_by_name
      end

      # Legacy `only_available: true` path: return allowed_types (with the
      # project_namespace? guard) and optionally filter by name.
      filter_by_name(provider.allowed_types, name)
    end

    private

    def filter_by_name(types, name)
      return types.sort_by { |type| type.name.downcase } if name.blank?

      names = Array.wrap(name).map(&:to_s)
      types
        .select { |type| names.include?(type.base_type.to_s) }
        .sort_by { |type| type.name.downcase }
    end

    def unavailable_container?
      @container.blank? || @container.is_a?(Namespaces::UserNamespace)
    end
  end
end
