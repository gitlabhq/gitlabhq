# frozen_string_literal: true

module WorkItems
  class TypesFinder
    def initialize(container:)
      @container = container
    end

    def execute(name: nil, only_available: false)
      return [] if unavailable_container?

      # The provider now returns both system-defined and custom work item types when the
      # work_item_configurable_types feature flag is enabled. When disabled, it falls back
      # to system-defined types only for backward compatibility.

      # TODO: The `name` and `only_available` parameters are deprecated and will be removed in 19.0.
      # See https://gitlab.com/gitlab-org/gitlab/-/work_items/593038
      provider = ::WorkItems::TypesFramework::Provider.new(@container)
      return Array.wrap(provider.find_by_base_type(name)) if name.present? && !only_available
      return provider.all_ordered_by_name unless only_available

      types = provider.allowed_types
      names = Array.wrap(name)
      types = types.select { |type| names.include?(type.base_type.to_s) } if name.present?
      types.sort_by { |type| type.name.downcase }
    end

    private

    def unavailable_container?
      @container.blank? || @container.is_a?(Namespaces::UserNamespace)
    end
  end
end
