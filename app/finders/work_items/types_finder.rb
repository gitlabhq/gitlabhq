# frozen_string_literal: true

module WorkItems
  class TypesFinder
    def initialize(container:)
      @container = container
    end

    def execute(name: nil, only_available: false)
      return [] if unavailable_container?

      provider = ::WorkItems::TypesFramework::Provider.new(@container)
      return Array.wrap(provider.find_by_base_type(name)) if name.present? && !only_available
      return provider.all_ordered_by_name unless only_available

      ::WorkItems::TypesFilter
        .new(container: @container)
        .allowed_types
        .then { |types| name.present? ? types.intersection(Array.wrap(name)) : types }
        .then { |types| provider.by_base_types_ordered_by_name(types) }
    end

    private

    def unavailable_container?
      @container.blank? || @container.is_a?(Namespaces::UserNamespace)
    end
  end
end
