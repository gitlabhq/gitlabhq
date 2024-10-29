# frozen_string_literal: true

module RuboCop
  module Cop
    module Rake
      # Flag global `require`s or `require_relative`s in rake files.
      #
      # Load dependencies lazily in `task` definitions if possible.
      #
      # @example
      #   # bad
      #
      #   require_relative 'gitlab/json'
      #   require 'json'
      #
      #   task :parse_json do
      #     Gitlab::Json.parse(...)
      #   end
      #
      #   namespace :json do
      #     require_relative 'gitlab/json'
      #     require 'json'
      #
      #     task :parse_json do
      #     end
      #   end
      #
      #   # good
      #
      #   task :parse_json do
      #     require_relative 'gitlab/json'
      #     require 'json'
      #
      #     Gitlab::Json.parse(...)
      #   end
      #
      #   namespace :json do
      #     task :parse_json do
      #       require_relative 'gitlab/json'
      #       require 'json'
      #
      #       Gitlab::Json.parse(...)
      #     end
      #   end
      #
      #   RSpec::Core::RakeTask.new(:parse_json) do |t, args|
      #     require_relative 'gitlab/json'
      #     require 'json'
      #
      #     Gitlab::Json.parse(...)
      #   end
      #
      #   # Requiring files which contain the word `task` is allowed.
      #   require 'some_gem/rake_task'
      #   require 'some_gem/rake_tasks'
      #
      #   SomeGem.define_tasks
      #
      #   # Loading in method definition as well.
      #   def load_deps
      #     require 'json'
      #   end
      #
      #   task :parse_json
      #     load_deps
      #   end
      #
      class Require < RuboCop::Cop::Base
        MSG = 'Load dependencies inside `task` definitions if possible.'

        METHODS = %i[require require_relative].freeze
        RESTRICT_ON_SEND = METHODS

        EAGER_EVALUATED_BLOCKS = %i[namespace].freeze

        def_node_matcher :require_method, <<~PATTERN
          (send nil? ${#{METHODS.map(&:inspect).join(' ')}} $_)
        PATTERN

        def on_send(node)
          return unless in_rake_file?(node)

          method, file = require_method(node)
          return unless method

          return if requires_task?(file)
          return if inside_block(node, skip: EAGER_EVALUATED_BLOCKS)
          return if inside_method?(node)

          add_offense(node)
        end

        private

        def in_rake_file?(node)
          File.extname(filepath(node)) == '.rake'
        end

        def filepath(node)
          node.location.expression.source_buffer.name
        end

        # Allow `require "foo/rake_task"`
        def requires_task?(file)
          file.source.include?('task')
        end

        def inside_block(node, skip:)
          node.each_ancestor(:block).any? do |block|
            !skip.include?(block.method_name)
          end
        end

        def inside_method?(node)
          node.each_ancestor(:def, :defs).any?
        end
      end
    end
  end
end
