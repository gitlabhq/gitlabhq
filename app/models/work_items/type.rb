# frozen_string_literal: true

# DEPRECATED: This class is retained only as a constant marker for GraphQL
# GlobalID resolution (GlobalIDType[::WorkItems::Type]).
#
# All type logic now lives in WorkItems::TypesFramework::SystemDefined::Type.
# Use WorkItems::TypesFramework::Provider for type lookups.
module WorkItems
  class Type # rubocop:disable Lint/EmptyClass -- Retained as a constant marker for GraphQL GlobalID resolution.
  end
end
