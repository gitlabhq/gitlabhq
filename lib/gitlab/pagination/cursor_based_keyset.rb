# frozen_string_literal: true

module Gitlab
  module Pagination
    module CursorBasedKeyset
      # Relation types that are enforced in this list
      # enforce the use of keyset pagination, thus erroring out requests
      # made with offset pagination above a certain limit.
      #
      # In many cases this could introduce a breaking change
      # so enforcement is optional.
      ENFORCED_TYPES = [Group, User].freeze

      def self.available_for_type?(relation)
        relation.klass.respond_to?(:supported_keyset_orderings)
      end

      def self.available?(cursor_based_request_context, relation)
        available_for_type?(relation) &&
          order_satisfied?(relation, cursor_based_request_context)
      end

      def self.enforced_for_type?(request_scope, relation)
        enforced = ENFORCED_TYPES
        enforced += [::Ci::Build] if ::Feature.enabled?(:enforce_ci_builds_pagination_limit, request_scope, type: :ops)
        enforced.include?(relation.klass)
      end

      def self.order_satisfied?(relation, cursor_based_request_context)
        order_by_from_request = cursor_based_request_context.order
        sort_from_request = cursor_based_request_context.sort

        !!relation.klass.supported_keyset_orderings[order_by_from_request]&.include?(sort_from_request)
      end
      private_class_method :order_satisfied?
    end
  end
end
