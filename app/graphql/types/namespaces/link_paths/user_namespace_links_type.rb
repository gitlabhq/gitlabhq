# frozen_string_literal: true

module Types
  module Namespaces
    module LinkPaths
      class UserNamespaceLinksType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'UserNamespaceLinks'
        implements ::Types::Namespaces::LinkPaths
      end
    end
  end
end

::Types::Namespaces::LinkPaths::UserNamespaceLinksType.prepend_mod
