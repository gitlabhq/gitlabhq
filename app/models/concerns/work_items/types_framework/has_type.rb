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

      delegate :icon_name, to: :work_item_type, allow_nil: true

      def exported_work_item_type
        if ::Feature.enabled?(:work_item_configurable_types, namespace&.root_ancestor)
          { 'name' => work_item_type&.name || ::WorkItems::TypesFramework::Provider.new.default_issue_type.name }
        else
          { 'base_type' => work_item_type&.base_type || 'issue' }
        end
      end

      def work_item_type=(value)
        work_item_type = work_items_types_provider.fetch_work_item_type(value)
        self.work_item_type_id = work_item_type&.persistable_id
      end

      private

      def validate_work_item_type_id
        return unless work_item_type_id
        return unless will_save_change_to_work_item_type_id?

        return if work_items_types_provider.find_by_id(work_item_type_id).present?

        errors.add(:work_item_type, 'is not a recognized work item type')
      end

      def work_items_types_provider
        ::WorkItems::TypesFramework::Provider.new(namespace)
      end
      strong_memoize_attr :work_items_types_provider
    end
  end
end
