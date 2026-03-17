# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module HasType
      include Gitlab::Utils::StrongMemoize

      extend ActiveSupport::Concern

      included do
        validate :validate_work_item_type_id
      end

      def work_item_type
        work_items_types_provider.fetch_work_item_type(work_item_type_id)
      end

      def work_item_type=(value)
        work_item_type = work_items_types_provider.fetch_work_item_type(value)
        self.work_item_type_id = work_item_type&.id
      end

      private

      def validate_work_item_type_id
        return unless work_item_type_id

        return if valid_work_item_type_id?

        errors.add(:work_item_type, 'must use a valid work item type ID')
      end

      def valid_work_item_type_id?
        work_items_types_provider.find_by_id(work_item_type_id).present?
      end

      def work_items_types_provider
        ::WorkItems::TypesFramework::Provider.new(namespace)
      end
      strong_memoize_attr :work_items_types_provider
    end
  end
end
