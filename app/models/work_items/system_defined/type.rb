# frozen_string_literal: true

module WorkItems
  module SystemDefined
    class Type
      include ActiveRecord::FixedItemsModel::Model
      include GlobalID::Identification
      include Gitlab::Utils::StrongMemoize

      attribute :name, :string
      attribute :base_type, :string
      attribute :icon_name, :string

      EE_BASE_TYPES = %w[epic key_result objective requirement].freeze

      class << self
        def fixed_items
          [
            WorkItems::SystemDefined::Types::Issue.configuration,
            WorkItems::SystemDefined::Types::Incident.configuration,
            WorkItems::SystemDefined::Types::Task.configuration,
            WorkItems::SystemDefined::Types::Ticket.configuration
          ]
        end

        def by_type(type)
          types = Array(type).map(&:to_s)
          where(base_type: types)
        end

        def find_by_type(type)
          find_by(base_type: type.to_s)
        end

        alias_method :default_by_type, :find_by_type

        def default_issue_type
          find_by_type(:issue)
        end

        def order_by_name_asc
          name_sorting_asc(all)
        end

        def by_ids_ordered_by_name(ids)
          name_sorting_asc(where(id: ids))
        end

        def by_base_type_ordered_by_name(types)
          name_sorting_asc(by_type(types))
        end

        private

        def name_sorting_asc(items)
          items.sort_by { |type| type.name.downcase }
        end
      end

      # Use legacy format
      def to_global_id(_options = {})
        ::Gitlab::GlobalId.build(self, model_name: 'WorkItems::Type', id: id)
      end
      alias_method :to_gid, :to_global_id

      def allowed_child_types_by_name
        child_type_ids = WorkItems::SystemDefined::HierarchyRestriction
          .where(parent_type_id: id)
          .map(&:child_type_id)

        self.class.by_ids_ordered_by_name(child_type_ids)
      end

      def allowed_parent_types_by_name
        parent_type_ids = WorkItems::SystemDefined::HierarchyRestriction
          .where(child_type_id: id)
          .map(&:parent_type_id)

        self.class.by_ids_ordered_by_name(parent_type_ids)
      end

      def supported_conversion_types(resource_parent, user)
        type_names = supported_conversion_base_types(resource_parent, user) - [base_type]

        self.class.by_base_type_ordered_by_name(type_names)
      end

      def allowed_child_types(authorize: false, resource_parent: nil)
        types = allowed_child_types_by_name

        return types unless authorize

        authorized_types(types, resource_parent, :child)
      end

      def allowed_parent_types(authorize: false, resource_parent: nil)
        types = allowed_parent_types_by_name

        return types unless authorize

        authorized_types(types, resource_parent, :parent)
      end

      def descendant_types
        descendant_types = []
        next_level_child_types = allowed_child_types.to_a

        loop do
          descendant_types += next_level_child_types

          # We remove types that we've already seen to avoid circular dependencies
          next_level_child_types = next_level_child_types.flat_map do |type|
            type.allowed_child_types.to_a
          end - descendant_types

          break if next_level_child_types.empty?
        end

        descendant_types
      end
      strong_memoize_attr :descendant_types

      private

      # resource_parent is used in EE
      def supported_conversion_base_types(_resource_parent, _user)
        self.class.all.map(&:base_type).excluding(*EE_BASE_TYPES)
      end

      # overridden in EE to check for EE-specific restrictions
      def authorized_types(types, _resource_parent, _relation)
        types
      end
    end
  end
end

WorkItems::SystemDefined::Type.prepend_mod
