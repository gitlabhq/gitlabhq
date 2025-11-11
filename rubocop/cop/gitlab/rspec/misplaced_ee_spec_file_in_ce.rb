# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

module RuboCop
  module Cop
    module Gitlab
      module RSpec
        # Checks for CE spec files that test EE-only classes.
        #
        # Specs in `spec/` (CE) should only test classes that exist in the CE codebase.
        # If a class is defined only in `ee/`, its spec should be in `ee/spec/`.
        #
        # See https://docs.gitlab.com/development/ee_features/#separation-of-ee-code-in-the-backend
        #
        # @example
        #   # bad
        #   # in spec/lib/api/helpers/audit_events_cursor_helper_spec.rb
        #   # when the class only exists in ee/lib/api/helpers/audit_events_cursor_helper.rb
        #   RSpec.describe API::Helpers::AuditEventsCursorHelper do
        #   end
        #
        #   # good
        #   # in ee/spec/lib/api/helpers/audit_events_cursor_helper_spec.rb
        #   RSpec.describe API::Helpers::AuditEventsCursorHelper do
        #   end
        #
        class MisplacedEeSpecFileInCe < RuboCop::Cop::RSpec::Base
          include RuboCop::Cop::RSpec::TopLevelGroup

          DOC_LINK = "https://docs.gitlab.com/development/ee_features/#separation-of-ee-code-in-the-backend"
          MSG = "This spec tests an EE-only class and should be moved to `%<suggested_path>s`. " \
            "The class `%<class_name>s` is only defined in `%<ee_class_path>s`. See #{DOC_LINK}.".freeze

          # @!method described_class_name(node)
          def_node_matcher :described_class_name, <<~PATTERN
          (block
            (send #rspec? {#ExampleGroups.all} $(const ...)
            )
            ...
          )
          PATTERN

          def on_top_level_group(node)
            spec_path = file_path_for_node(node.send_node).sub(%r{\A#{rails_root}/}, '')

            # Only check CE specs (not in ee/ directory)
            return unless ce_spec?(spec_path)

            const = described_class_name(node)
            return unless const

            class_name = const.const_name

            # Check if class exists only in EE
            ee_class_path = find_ee_only_class_path(spec_path)
            return unless ee_class_path

            suggested_path = suggest_ee_spec_path(spec_path)

            add_offense(
              const,
              message: format(
                MSG,
                suggested_path: suggested_path,
                class_name: class_name,
                ee_class_path: ee_class_path
              )
            )
          end

          private

          def ce_spec?(path)
            path.start_with?('spec/')
          end

          def find_ee_only_class_path(spec_path)
            # Extract spec type and file path from spec path
            # e.g., "spec/lib/api/helpers/my_helper_spec.rb" -> ["lib", "api/helpers/my_helper.rb"]
            match = spec_path.match(%r{spec/(?<spec_type>[^/]+)/(?<file_path>.+)_spec\.rb})
            return unless match

            spec_type = match[:spec_type]
            file_path = "#{match[:file_path]}.rb"

            # Determine the application directory based on spec type
            app_dir = spec_type == 'lib' ? 'lib' : "app/#{spec_type}"

            ce_class_path = File.join(app_dir, file_path)
            ee_class_path = File.join('ee', app_dir, file_path)

            # Check if class exists only in EE (not in CE)
            return unless File.exist?(File.join(rails_root, ee_class_path))
            return if File.exist?(File.join(rails_root, ce_class_path))

            ee_class_path
          end

          def suggest_ee_spec_path(spec_path)
            # Convert spec/lib/foo_spec.rb -> ee/spec/lib/foo_spec.rb
            "ee/#{spec_path}"
          end

          def file_path_for_node(node)
            node.source_range.source_buffer.name
          end

          def rails_root
            File.expand_path('../../../..', __dir__)
          end
        end
      end
    end
  end
end
