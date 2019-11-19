# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      class Instrumentation
        # Replace the resolver for the field with one that will only return the
        # resolved object if the permissions check is successful.
        def instrument(_type, field)
          service = AuthorizeFieldService.new(field)

          if service.authorizations? && !resolver_skips_authorizations?(field)
            field.redefine { resolve(service.authorized_resolve) }
          else
            field
          end
        end

        def resolver_skips_authorizations?(field)
          field.metadata[:resolver].try(:skip_authorizations?)
        end
      end
    end
  end
end
