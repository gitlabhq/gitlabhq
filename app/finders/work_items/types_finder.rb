# frozen_string_literal: true

module WorkItems
  class TypesFinder
    def initialize(container:)
      @container = container
    end

    # list_all should be removed soon
    # https://gitlab.com/gitlab-org/gitlab/-/issues/540763
    def execute(name: nil, list_all: false)
      return WorkItems::Type.none if resource_parent.blank?
      return WorkItems::Type.by_type(name) if name.present?
      return order(WorkItems::Type) if list_all

      WorkItems::Type.allowed_types(resource_parent)
        .then { |allowed_types| WorkItems::Type.by_type(allowed_types) }
        .then { |scope| order(scope) }
    end

    private

    def resource_parent
      @resource_parent ||=
        case @container
        when ::Namespaces::ProjectNamespace
          @container.project
        when ::Group, ::Project
          @container
        end
    end

    def order(scope)
      scope.order_by_name_asc
    end
  end
end
