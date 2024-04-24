# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      module AuthorizeResource
        extend ActiveSupport::Concern
        ConfigurationError = Class.new(StandardError)

        RESOURCE_ACCESS_ERROR = "The resource that you are attempting to access does " \
          "not exist or you don't have permission to perform this action"

        class_methods do
          def required_permissions
            # If the `#authorize` call is used on multiple classes, we add the
            # permissions specified on a subclass, to the ones that were specified
            # on its superclass.
            @required_permissions ||= call_superclass_method(:required_permissions, []).dup
          end

          def authorize(*permissions)
            required_permissions.concat(permissions)
          end

          def authorizes_object?
            return true if call_superclass_method(:authorizes_object?, false)

            defined?(@authorizes_object) ? @authorizes_object : false
          end

          def authorizes_object!
            @authorizes_object = true
          end

          def raise_resource_not_available_error!(msg = RESOURCE_ACCESS_ERROR)
            raise ::Gitlab::Graphql::Errors::ResourceNotAvailable, msg
          end

          private

          def call_superclass_method(method_name, or_else)
            return or_else unless respond_to?(:superclass) && superclass.respond_to?(method_name)

            superclass.send(method_name) # rubocop: disable GitlabSecurity/PublicSend
          end
        end

        def find_object(id:)
          GitlabSchema.find_by_gid(id)
        end

        def authorized_find!(*args, **kwargs)
          object = Graphql::Lazy.force(find_object(*args, **kwargs))

          authorize!(object)

          object
        end

        def authorize!(object)
          raise_resource_not_available_error! unless authorized_resource?(object)
        end

        def authorized_resource?(object)
          raise ConfigurationError, "#{self.class.name} has no authorizations" if self.class.authorization.none?

          self.class.authorization.ok?(object, current_user, scope_validator: context[:scope_validator])
        end

        def raise_resource_not_available_error!(...)
          self.class.raise_resource_not_available_error!(...)
        end
      end
    end
  end
end
