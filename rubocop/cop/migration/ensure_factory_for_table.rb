# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Checks for `create_table` calls without a corresponding factory.
      #
      # @example
      #
      #   # bad
      #
      #   create_table :users do |t|
      #     t.string :name
      #     t.timestamps
      #   end
      #   # spec/factories/users.rb does not exist
      #
      # @example
      #
      #   # good
      #
      #   create_table :users do |t|
      #     t.string :name
      #     t.timestamps
      #   end
      #   # spec/factories/users.rb exists
      class EnsureFactoryForTable < RuboCop::Cop::Base
        MSG = %(No factory found for the table `%s`.)

        def_node_matcher :table_definition?, <<~PATTERN
          (send nil? :create_table ...)
        PATTERN

        def on_send(node)
          return unless table_definition?(node)

          table_name_node = node.arguments.first
          return unless table_name_node.str_type? || table_name_node.sym_type?

          table_name = table_name_node.value
          factory_file_name = "#{table_name}.rb"
          factories_directory = File.join('spec', 'factories')
          return unless Dir.exist?(factories_directory)

          return if Dir.glob("{,ee/,jh/}spec/factories/**/#{factory_file_name}").any?

          add_offense(node, message: MSG % table_name)
        end
      end
    end
  end
end
