# frozen_string_literal: true

module Types
  module Packages
    class PackageLinksType < BaseObject
      graphql_name 'PackageLinks'
      description 'Represents links to perform actions on the package'
      authorize :read_package

      include ::Routing::PackagesHelper

      field :web_path, GraphQL::Types::String, null: true, description: 'Path to the package details page.'

      def web_path
        return unless object.detailed_info?

        package_path(object)
      end
    end
  end
end
