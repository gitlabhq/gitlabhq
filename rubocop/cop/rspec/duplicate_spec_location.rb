# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

module RuboCop
  module Cop
    module RSpec
      # Cop that detects duplicate EE spec files
      #
      # There should not be files in both ee/spec/*/ee/my_spec.rb and ee/spec/*/my_spec.rb
      #
      #  # bad
      #  ee/spec/controllers/my_spec.rb      # describe MyClass
      #  ee/spec/controllers/ee/my_spec.rb   # describe MyClass
      #
      #  # good, spec for EE extension code
      #  ee/spec/controllers/ee/my_spec.rb   # describe MyClass
      #
      #  # good, spec for EE only code
      #  ee/spec/controllers/my_spec.rb      # describe MyClass
      #
      class DuplicateSpecLocation < RuboCop::Cop::RSpec::Base
        include RuboCop::Cop::RSpec::TopLevelGroup

        MSG = 'Duplicate spec location in `%<path>s`.'

        def on_top_level_group(node)
          path = file_path_for_node(node.send_node).sub(%r{\A#{rails_root}/}, '')
          duplicate_path = find_duplicate_path(path)

          return unless duplicate_path && File.exist?(File.join(rails_root, duplicate_path))

          add_offense(node.send_node, message: format(MSG, path: duplicate_path))
        end

        private

        def ee_spec?(path)
          File.fnmatch?('ee/spec/**/*.rb', path, File::FNM_PATHNAME)
        end

        def find_duplicate_path(path)
          return unless ee_spec?(path)

          if File.fnmatch?('ee/spec/**/ee/**', path)
            path.match('\A(ee/spec/[^/]+)/ee/(.+)') do |match|
              File.join(match[1], match[2])
            end
          else
            path.match('\A(ee/spec/[^/]+)/(.+)') do |match|
              File.join(match[1], 'ee', match[2])
            end
          end
        end

        def file_path_for_node(node)
          node.location.expression.source_buffer.name
        end

        def rails_root
          File.expand_path('../../..', __dir__)
        end
      end
    end
  end
end
