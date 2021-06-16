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
            @required_permissions ||= if respond_to?(:superclass) && superclass.respond_to?(:required_permissions)
                                        superclass.required_permissions.dup
                                      else
                                        []
                                      end
          end

          def authorize(*permissions)
            required_permissions.concat(permissions)
          end

          def authorizes_object?
            defined?(@authorizes_object) ? @authorizes_object : false
          end

          def authorizes_object!
            @authorizes_object = true
          end

          def raise_resource_not_available_error!(msg = RESOURCE_ACCESS_ERROR)
            raise ::Gitlab::Graphql::Errors::ResourceNotAvailable, msg
          end
        end

        def find_object(*args)
          raise NotImplementedError, "Implement #find_object in #{self.class.name}"
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

          self.class.authorization.ok?(object, current_user)
        end

        def raise_resource_not_available_error!(*args)
          self.class.raise_resource_not_available_error!(*args)
        end
      end
    end
  end
end
