module Gitlab
  module Graphql
    module Authorize
      module AuthorizeResource
        extend ActiveSupport::Concern

        included do
          extend Gitlab::Graphql::Authorize
        end

        def find_object(*args)
          raise NotImplementedError, "Implement #find_object in #{self.class.name}"
        end

        def authorized_find(*args)
          object = find_object(*args)

          object if authorized?(object)
        end

        def authorized_find!(*args)
          object = find_object(*args)
          authorize!(object)

          object
        end

        def authorize!(object)
          unless authorized?(object)
            raise Gitlab::Graphql::Errors::ResourceNotAvailable,
                  "The resource that you are attempting to access does not exist or you don't have permission to perform this action"
          end
        end

        def authorized?(object)
          self.class.required_permissions.all? do |ability|
            # The actions could be performed across multiple objects. In which
            # case the current user is common, and we could benefit from the
            # caching in `DeclarativePolicy`.
            Ability.allowed?(current_user, ability, object, scope: :user)
          end
        end
      end
    end
  end
end
