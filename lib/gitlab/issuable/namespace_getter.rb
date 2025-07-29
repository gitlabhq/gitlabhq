# frozen_string_literal: true

module Gitlab
  module Issuable
    class NamespaceGetter
      INVALID_ISSUABLE_ERROR = Class.new(StandardError)

      def initialize(issuable, excluded_issuable_types: [], allow_nil: false)
        @issuable = issuable
        @excluded_issuable_types = excluded_issuable_types
        @allow_nil = allow_nil

        raise_invalid_issuable_error if excluded_issuable_types.include?(issuable.class)
      end

      def namespace_id
        case issuable
        when Issue
          issuable.namespace_id
        when MergeRequest
          issuable.project.project_namespace_id
        else
          return if @allow_nil && issuable.nil?

          raise_invalid_issuable_error
        end
      end

      private

      attr_reader :issuable

      def raise_invalid_issuable_error
        raise INVALID_ISSUABLE_ERROR, "#{issuable.class.name} is not a supported Issuable type"
      end
    end
  end
end

Gitlab::Issuable::NamespaceGetter.prepend_mod
