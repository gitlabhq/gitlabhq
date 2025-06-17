# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

module RuboCop
  module Cop
    module Gitlab
      module RSpec
        # Checks EE spec files for misplaced EE spec files
        # in ee/spec/ (but not in ee/spec/*/ee/) should have matching application files.
        # See https://docs.gitlab.com/development/ee_features/#testing-ee-features-based-on-ce-features.
        #
        # @example
        #   # bad
        #   ee/spec/models/my_model_spec.rb      # When an existing prepended module ee/app/models/ee/my_model.rb
        #
        #   # good
        #   ee/spec/models/my_model_spec.rb      # With matching ee/app/models/my_model.rb
        #   ee/spec/models/ee/my_model_spec.rb   # EE extension specs can have added functionality
        #                                          without a matching application file
        #
        class MisplacedEeSpecFile < RuboCop::Cop::RSpec::Base
          include RuboCop::Cop::RSpec::TopLevelGroup

          DOC_LINK = "https://docs.gitlab.com/development/ee_features/#testing-ee-features-based-on-ce-features"
          MSG = "Misplaced EE spec file. This spec should be moved to `%<suggested_spec_path>s` since " \
            "there is an EE extension file: `%<extension_path>s`. See #{DOC_LINK}.".freeze

          def on_top_level_group(node)
            path = file_path_for_node(node.send_node).sub(%r{\A#{rails_root}/}, '')
            path_components = extract_path_components(path)

            return unless path_components

            spec_type, spec_file_path = path_components
            application_file_path = transform_spec_to_application_path(spec_file_path)

            return if ee_only_application_path_exists?(spec_type, application_file_path)

            extension_path = ee_extension_path_for(spec_type, application_file_path)

            return unless extension_path

            suggested_spec_path = suggested_spec_path(spec_type, spec_file_path)

            add_offense(
              node.send_node,
              message: format(MSG, suggested_spec_path: suggested_spec_path, extension_path: extension_path)
            )
          end

          private

          def ee_extension_path_for(spec_type, file_path)
            extension_path = if spec_type == 'lib'
                               # Special case for lib specs
                               "ee/lib/ee/#{file_path}"
                             else
                               "ee/app/#{spec_type}/ee/#{file_path}"
                             end

            extension_path if File.exist?(File.join(rails_root, extension_path))
          end

          def ee_only_application_path_exists?(spec_type, file_path)
            # Special case for lib specs
            path = if spec_type == 'lib'
                     "ee/lib/#{file_path}"
                   else
                     "ee/app/#{spec_type}/#{file_path}"
                   end

            File.exist?(File.join(rails_root, path))
          end

          def suggested_spec_path(spec_type, file_path)
            "ee/spec/#{spec_type}/ee/#{file_path}"
          end

          def extract_path_components(spec_path)
            match = spec_path.match(%r{ee/spec/(?<spec_type>[^/]+)/(?<file_path>.+)})
            return unless match

            spec_type = match[:spec_type]
            file_path = match[:file_path]

            [spec_type, file_path]
          end

          def transform_spec_to_application_path(file_path)
            file_path.sub('_spec.rb', '.rb')
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
