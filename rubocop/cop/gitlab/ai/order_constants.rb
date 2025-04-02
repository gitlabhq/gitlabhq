# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module Gitlab
      module Ai
        # This cop enforces the order of the ConfigFiles::Constants.
        #
        # @example
        #
        #   # bad
        #   [ConfigFiles::PythonPoetry, ConfigFiles::CConanPy, ConfigFiles::CConanTxt]
        #   [ConfigFiles::PythonPoetry, ConfigFiles::PythonPoetryLock, ConfigFiles::RubyGemsLock]
        #
        #   # good
        #   [ConfigFiles::CConanPy, ConfigFiles::CConanTxt, ConfigFiles::PythonPoetry]
        #   [ConfigFiles::PythonPoetryLock, ConfigFiles::PythonPoetry, ConfigFiles::RubyGemsLock]
        #
        class OrderConstants < RuboCop::Cop::Base
          MSG = 'Order lock files by language (alphabetically), then by precedence. ' \
            'Lock files should appear first before their non-lock file counterparts.'

          # @!method config_file_classes(node)
          def_node_matcher :config_file_classes, <<~PATTERN
            $(
              casgn nil? :CONFIG_FILE_CLASSES (send $array ...)
            )
          PATTERN

          # @!method config_files_constants?(node)
          def_node_matcher :config_files_constants?, <<~PATTERN
            $(module
              (const nil? :ConfigFiles)
              (module
                (const nil? :Constants)
                ...
              )
            )
          PATTERN

          def on_casgn(node)
            # we want to make sure that we are running the cop only on
            # ConfigFiles::Constants::CONFIG_FILES_CONSTANTS
            return unless config_files_constants?(node.parent.parent)

            _matcher, constants_array = config_file_classes(node)

            constants_names = constants_array.child_nodes.map(&:source)

            return if constants_names == sort_with_lock_priority(constants_names)

            add_offense(node)
          end

          private

          def sort_with_lock_priority(config_file_classes)
            base_classes = config_file_classes.group_by { |class_name| class_name.gsub("Lock", "") }

            base_classes.each_value do |classes|
              classes.sort! do |a, b|
                if b.include?("Lock")
                  1
                else
                  (a.include?("Lock") ? -1 : (a <=> b))
                end
              end
            end

            # Sort the base names alphabetically and flatten the result
            base_classes.keys.sort.flat_map { |base_name| base_classes[base_name] }
          end
        end
      end
    end
  end
end
