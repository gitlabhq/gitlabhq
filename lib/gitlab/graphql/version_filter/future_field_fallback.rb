# frozen_string_literal: true

# Overrides methods in
# https://github.com/rmosolgo/graphql-ruby/blob/v2.3.17/lib/graphql/schema/member/has_fields.rb#L100C37-L130
# to prevent missing field errors during a rolling deploy.
# See https://graphql-ruby.org/schema/dynamic_types.html#using-fieldscontext-and-get_fieldname-context
module Gitlab
  module Graphql
    module VersionFilter
      module FutureFieldFallback
        extend ActiveSupport::Concern

        class_methods do
          def get_field(field_name, context = GraphQL::Query::NullContext.instance)
            field = super
            return field unless future_field?(name: field_name, field: field, context: context)

            fallback_field(name: field_name)
          end

          private

          def future_field?(name:, field:, context:)
            return false if field.present?
            # Introspection fields like __typename resolve through the
            # schema's dynamic fields; a fallback here would shadow them.
            return false if name.start_with?('__')

            # Only names tagged with @gl_introduced get the fallback, so a
            # typo in an untagged field still raises undefinedField.
            context.fetch(:future_field_names, nil)&.include?(name)
          end

          def fallback_field(name:)
            GraphQL::Schema::Field.new(
              owner: self,
              name: name,
              resolver_class: Resolvers::NilResolver
            )
          end
        end
      end
    end
  end
end
