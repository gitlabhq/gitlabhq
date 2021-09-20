# frozen_string_literal: true

module Gitlab
  module Pagination
    module CursorBasedKeyset
      SUPPORTED_ORDERING = {
        Group => { name: :asc }
      }.freeze

      def self.available_for_type?(relation)
        SUPPORTED_ORDERING.key?(relation.klass)
      end

      def self.available?(cursor_based_request_context, relation)
        available_for_type?(relation) &&
        order_satisfied?(relation, cursor_based_request_context)
      end

      def self.order_satisfied?(relation, cursor_based_request_context)
        order_by_from_request = cursor_based_request_context.order_by

        SUPPORTED_ORDERING[relation.klass] == order_by_from_request
      end
      private_class_method :order_satisfied?
    end
  end
end
