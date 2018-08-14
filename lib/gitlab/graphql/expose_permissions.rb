module Gitlab
  module Graphql
    module ExposePermissions
      extend ActiveSupport::Concern
      prepended do
        def self.expose_permissions(permission_type, description: 'Permissions for the current user on the resource')
          field :user_permissions, permission_type,
                description: description,
                null: false,
                resolve: -> (obj, _, _) { obj }
        end
      end
    end
  end
end
