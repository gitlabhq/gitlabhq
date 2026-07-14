# frozen_string_literal: true

require_relative '../spec_permission_scanner'

module Tasks
  module Gitlab
    module Permissions
      module Routes
        # Scans REST API request specs for granular token authorization tests.
        class SpecPermissionScanner < ::Tasks::Gitlab::Permissions::SpecPermissionScanner
          EXAMPLE_NAMES = [
            'authorizing granular token permissions',
            'granular token permissions authorizable'
          ].freeze

          SPEC_DIRS = %w[
            spec/requests/api
            ee/spec/requests/api
            ee/spec/requests/ee/api
            spec/support/shared_examples/requests/api
            ee/spec/support/shared_examples/requests/api
          ].freeze

          # Derives the suggested spec file path from an API source file path.
          # Used in error messages as a hint -- the scanner checks all spec dirs globally,
          # not just this path.
          # e.g. lib/api/notes.rb        -> spec/requests/api/notes_spec.rb
          #      ee/lib/api/epics.rb     -> ee/spec/requests/api/epics_spec.rb
          #      ee/lib/ee/api/groups.rb -> ee/spec/requests/api/groups_spec.rb
          def derive_spec_path(source_file)
            source_file
              .sub(%r{^ee/lib/ee/api/}, 'ee/spec/requests/api/')
              .sub(%r{^ee/lib/api/}, 'ee/spec/requests/api/')
              .sub(%r{^lib/api/}, 'spec/requests/api/')
              .sub(/\.rb$/, '_spec.rb')
          end
        end
      end
    end
  end
end
