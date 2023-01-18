# frozen_string_literal: true

module Gitlab
  module Pagination
    module CursorBasedKeyset
      SUPPORTED_ORDERING = {
        Group => { name: :asc },
        AuditEvent => { id: :desc },
        ::Ci::Build => { id: :desc }
      }.freeze

      # Relation types that are enforced in this list
      # enforce the use of keyset pagination, thus erroring out requests
      # made with offset pagination above a certain limit.
      #
      # In many cases this could introduce a breaking change
      # so enforcement is optional.
      ENFORCED_TYPES = [Group].freeze

      def self.available_for_type?(relation)
        SUPPORTED_ORDERING.key?(relation.klass)
      end

      def self.available?(cursor_based_request_context, relation)
        available_for_type?(relation) &&
          order_satisfied?(relation, cursor_based_request_context)
      end

      def self.enforced_for_type?(relation)
        ENFORCED_TYPES.include?(relation.klass)
      end

      def self.order_satisfied?(relation, cursor_based_request_context)
        order_by_from_request = cursor_based_request_context.order_by

        SUPPORTED_ORDERING[relation.klass] == order_by_from_request
      end
      private_class_method :order_satisfied?
    end
  end
end
