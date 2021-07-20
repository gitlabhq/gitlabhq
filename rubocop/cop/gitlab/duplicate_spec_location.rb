# frozen_string_literal: true

require 'rubocop/rspec/top_level_describe'

module RuboCop
  module Cop
    module Gitlab
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
      class DuplicateSpecLocation < RuboCop::Cop::Cop
        include RuboCop::RSpec::TopLevelDescribe

        MSG = 'Duplicate spec location in `%<path>s`.'

        def on_top_level_describe(node, _args)
          path = file_path_for_node(node).sub(%r{\A#{rails_root}/}, '')
          duplicate_path = find_duplicate_path(path)

          if duplicate_path && File.exist?(File.join(rails_root, duplicate_path))
            add_offense(node, message: format(MSG, path: duplicate_path))
          end
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
