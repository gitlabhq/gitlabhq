# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module SystemDefined
      class HierarchyRestriction
        include ActiveRecord::FixedItemsModel::Model

        auto_generate_ids!

        attribute :parent_type_id, :integer
        attribute :child_type_id, :integer
        attribute :maximum_depth, :integer

        class << self
          def with_parent_type_id(parent_type_id)
            where(parent_type_id: parent_type_id)
          end

          def hierarchy_relationship_allowed?(parent_type_id:, child_type_id:)
            where(parent_type_id: parent_type_id, child_type_id: child_type_id).present?
          end

          def fixed_items
            Type.all.flat_map do |type|
              type.allowed_child_types_config.map do |child_type_config|
                child_type = Type.find_by_type(child_type_config[:type])

                next [] unless child_type

                {
                  parent_type_id: type.id,
                  child_type_id: child_type.id,
                  maximum_depth: child_type_config[:maximum_depth]
                }
              end
            end
          end
        end
      end
    end
  end
end
