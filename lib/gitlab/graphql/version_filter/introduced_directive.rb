# frozen_string_literal: true

module Gitlab
  module Graphql
    module VersionFilter
      # Define the introduced directive for controlling field visibility based on version
      class IntroducedDirective < GraphQL::Schema::Directive
        graphql_name "gl_introduced"
        description <<~DESC.squish
        Marks a field as introduced in a specific version.
        Fields with a version higher than the current one will return null.
        DESC

        argument :version,
          String,
          required: true,
          description: "The version when this field was introduced (e.g. '18.1.0')"

        locations(
          GraphQL::Schema::Directive::FIELD,
          GraphQL::Schema::Directive::INLINE_FRAGMENT
        )
      end
    end
  end
end
