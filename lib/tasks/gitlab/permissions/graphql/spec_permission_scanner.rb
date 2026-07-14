# frozen_string_literal: true

require_relative '../spec_permission_scanner'

module Tasks
  module Gitlab
    module Permissions
      module Graphql
        # Scans GraphQL request specs for granular token authorization tests.
        class SpecPermissionScanner < ::Tasks::Gitlab::Permissions::SpecPermissionScanner
          EXAMPLE_NAMES = [
            'authorizing granular token permissions for GraphQL'
          ].freeze

          SPEC_DIRS = %w[
            spec/requests/api/graphql
            ee/spec/requests/api/graphql
            spec/support/shared_examples/graphql
            ee/spec/support/shared_examples/graphql
          ].freeze
        end
      end
    end
  end
end
