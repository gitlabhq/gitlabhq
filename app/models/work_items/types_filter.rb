# frozen_string_literal: true

module WorkItems
  class TypesFilter
    include ::Gitlab::Utils::StrongMemoize

    class << self
      include ::Gitlab::Utils::StrongMemoize

      def base_types
        ::WorkItems::TypesFramework::Provider.unfiltered_base_types.map(&:to_s)
      end
      strong_memoize_attr :base_types
    end
  end
end

WorkItems::TypesFilter.prepend_mod
