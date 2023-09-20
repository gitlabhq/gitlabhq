# frozen_string_literal: true

module Types
  module Ci
    # JobBaseField ensures that only allow-listed fields can be returned without a permission check.
    # All other fields go through a permissions check based on the :job_field_authorization value passed in the context.
    # rubocop: disable Graphql/AuthorizeTypes
    class JobBaseField < ::Types::BaseField
      PUBLIC_FIELDS = %i[allow_failure duration id kind status created_at finished_at queued_at queued_duration
        updated_at runner].freeze

      attr_accessor :if_unauthorized

      def initialize(**kwargs, &block)
        @if_unauthorized = kwargs.delete(:if_unauthorized)

        super
      end

      def authorized?(object, args, ctx)
        current_user = ctx[:current_user]
        permission = ctx[:job_field_authorization]

        if permission.nil? ||
            PUBLIC_FIELDS.include?(ctx[:current_field].original_name) ||
            current_user.can?(permission, object)
          return super
        end

        false
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
