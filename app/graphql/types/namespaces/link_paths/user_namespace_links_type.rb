# frozen_string_literal: true

module Types
  module Namespaces
    module LinkPaths
      class UserNamespaceLinksType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'UserNamespaceLinks'
        implements ::Types::Namespaces::LinkPaths

        # Do not expose the export email for user namespaces, since exporting work items on this namespace type is not
        # supported
        def user_export_email; end
      end
    end
  end
end

::Types::Namespaces::LinkPaths::UserNamespaceLinksType.prepend_mod
