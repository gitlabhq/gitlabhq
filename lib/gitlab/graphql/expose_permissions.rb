# frozen_string_literal: true

module Gitlab
  module Graphql
    module ExposePermissions
      extend ActiveSupport::Concern
      prepended do
        def self.expose_permissions(
          permission_type,
          description: 'Permissions for the current user on the resource',
          &block)
          field :user_permissions, permission_type,
            description: description,
            null: false,
            method: :itself,
            &block
        end
      end
    end
  end
end
