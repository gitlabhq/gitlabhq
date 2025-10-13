# frozen_string_literal: true

require 'rubocop/cop/rspec/base'
require 'rubocop/cop/rspec/mixin/top_level_group'

module RuboCop
  module Cop
    module RSpec
      # Checks that files with top-level `describe` blocks have the correct file naming convention.
      #
      # @example
      #
      #   # bad
      #   # in file: spec/models/user.rb
      #   describe User do
      #     # ...
      #   end
      #
      #   # in file: spec/lib/helper.rb
      #   describe Helper do
      #     # ...
      #   end
      #
      #   # in file: spec/controllers/application.rb
      #   describe ApplicationController do
      #     # ...
      #   end
      #
      #   # good
      #   # in file: spec/models/user_spec.rb
      #   describe User do
      #     # ...
      #   end
      #
      #   # in file: spec/lib/helper_spec.rb
      #   describe Helper do
      #     # ...
      #   end
      #
      #   # in file: spec/controllers/application_controller_spec.rb
      #   describe ApplicationController do
      #     # ...
      #   end
      class TopLevelDescribePath < RuboCop::Cop::RSpec::Base
        include RuboCop::Cop::RSpec::TopLevelGroup

        MESSAGE = 'A file with a top-level `describe` must end in _spec.rb.'

        def on_top_level_example_group(node)
          return if acceptable_file_path?(processed_source.file_path)

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
