# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module HasType
      include Gitlab::Utils::StrongMemoize

      extend ActiveSupport::Concern

      def work_item_type
        if use_system_defined_types?
          work_items_types_provider.fetch_work_item_type(work_item_type_id)
        else
          super
        end
      end

      def work_item_type=(value)
        if use_system_defined_types?
          work_item_type = work_items_types_provider.fetch_work_item_type(value)
          self.work_item_type_id = work_item_type&.id
        else
          super
        end
      end

      private

      def work_items_types_provider
        ::WorkItems::TypesFramework::Provider.new(namespace)
      end
      strong_memoize_attr :work_items_types_provider

      def use_system_defined_types?
        Feature.enabled?(:work_item_system_defined_type, :instance)
      end
    end
  end
end
