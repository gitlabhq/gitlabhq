# frozen_string_literal: true

require 'rubocop/rspec/top_level_describe'

module RuboCop
  module Cop
    module RSpec
      class TopLevelDescribePath < RuboCop::Cop::Cop
        include RuboCop::RSpec::TopLevelDescribe

        MESSAGE = 'A file with a top-level `describe` must end in _spec.rb.'
        SHARED_EXAMPLES = %i[shared_examples shared_examples_for].freeze

        def on_top_level_describe(node, args)
          return if acceptable_file_path?(processed_source.buffer.name)
          return if shared_example?(node)

          add_offense(node, message: MESSAGE)
        end

        private

        def acceptable_file_path?(path)
          File.fnmatch?('*_spec.rb', path) || File.fnmatch?('*/frontend/fixtures/*', path) || File.fnmatch?('*/docs_screenshots/*_docs.rb', path)
        end

        def shared_example?(node)
          node.ancestors.any? do |node|
            node.respond_to?(:method_name) && SHARED_EXAMPLES.include?(node.method_name)
          end
        end
      end
    end
  end
end
