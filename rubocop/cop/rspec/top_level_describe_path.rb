# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

module RuboCop
  module Cop
    module RSpec
      class TopLevelDescribePath < RuboCop::Cop::RSpec::Base
        include RuboCop::Cop::RSpec::TopLevelGroup

        MESSAGE = 'A file with a top-level `describe` must end in _spec.rb.'

        def on_top_level_example_group(node)
          return if acceptable_file_path?(processed_source.buffer.name)

          add_offense(node.send_node, message: MESSAGE)
        end

        private

        def acceptable_file_path?(path)
          File.fnmatch?('*_spec.rb', path) || File.fnmatch?('*/frontend/fixtures/*', path) || File.fnmatch?('*/docs_screenshots/*_docs.rb', path)
        end
      end
    end
  end
end
