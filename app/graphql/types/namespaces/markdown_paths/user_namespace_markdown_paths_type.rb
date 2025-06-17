# frozen_string_literal: true

module Types
  module Namespaces
    module MarkdownPaths
      class UserNamespaceMarkdownPathsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'UserNamespaceMarkdownPaths'
        implements ::Types::Namespaces::MarkdownPaths
      end
    end
  end
end
