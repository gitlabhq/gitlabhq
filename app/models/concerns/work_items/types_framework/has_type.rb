# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module HasType
      include Gitlab::Utils::StrongMemoize

      extend ActiveSupport::Concern

      def work_item_type
        work_items_types_provider.fetch_work_item_type(work_item_type_id)
      end

      def work_item_type=(value)
        work_item_type = work_items_types_provider.fetch_work_item_type(value)
        self.work_item_type_id = work_item_type&.id
      end

      private

      def work_items_types_provider
        ::WorkItems::TypesFramework::Provider.new(namespace)
      end
      strong_memoize_attr :work_items_types_provider
    end
  end
end
