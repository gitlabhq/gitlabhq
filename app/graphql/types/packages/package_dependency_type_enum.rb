# frozen_string_literal: true

module Types
  module Packages
    class PackageDependencyTypeEnum < BaseEnum
      graphql_name 'PackageDependencyType'

      ::Packages::DependencyLink.dependency_types.keys.each do |type|
        value type.to_s.underscore.upcase, description: "#{type} dependency type", value: type.to_s
      end
    end
  end
end
