# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module Custom
      class TypePolicy < BasePolicy
        delegate { @subject.namespace || @subject.organization }

        condition(:configurable_work_item_types_licensed) do
          if @subject.namespace
            @subject.namespace.licensed_feature_available?(:configurable_work_item_types)
          else
            # License check for organization level work item types
            License.feature_available?(:configurable_work_item_types)
          end
        end

        rule { ~configurable_work_item_types_licensed }.policy do
          prevent :read_work_item_type
        end
      end
    end
  end
end
