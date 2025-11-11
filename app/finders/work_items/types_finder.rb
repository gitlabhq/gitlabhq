# frozen_string_literal: true

module WorkItems
  class TypesFinder
    def initialize(container:)
      @container = container
    end

    def execute(name: nil, only_available: false)
      return WorkItems::Type.none if unavailable_container?
      return order(WorkItems::Type.by_type(name)) if name.present? && !only_available
      return order(WorkItems::Type) unless only_available

      ::WorkItems::TypesFilter
        .new(container: @container)
        .allowed_types
        .then { |types| name.present? ? types.intersection(Array.wrap(name)) : types }
        .then { |types| WorkItems::Type.by_type(types) }
        .then { |scope| order(scope) }
    end

    private

    def unavailable_container?
      @container.blank? || @container.is_a?(Namespaces::UserNamespace)
    end

    def order(scope)
      scope.order_by_name_asc
    end
  end
end
