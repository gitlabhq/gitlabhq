# frozen_string_literal: true

module BulkImports
  module Uniquify
    private

    def uniquify(namespace, data_item, data_type)
      return data_item unless namespace.present?

      children_items = Set.new

      # index_namespaces_on_parent_id_and_id index supports this
      Namespace.by_parent(namespace).each_batch do |relation|
        children_items.merge(relation.pluck(data_type).to_set) # rubocop: disable CodeReuse/ActiveRecord
      end

      return data_item unless children_items.include?(data_item)

      data_item = Gitlab::Utils::Uniquify.new(1).string(->(counter) { "#{data_item}_#{counter}" }) do |base|
        children_items.include?(base)
      end
    end
  end
end
