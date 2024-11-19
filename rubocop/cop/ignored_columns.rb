# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that flags the usage of `ActiveRecord::Base.ignored_columns=` directly
    #
    # @example
    #   # bad
    #   class User < ApplicationRecord
    #     self.ignored_columns = [:name]
    #     self.ignored_columns += [:full_name]
    #   end
    #
    #   # good
    #   class User < ApplicationRecord
    #     ignore_column :name, remove_after: '2023-05-22', remove_with: '16.0'
    #     ignore_column :full_name, remove_after: '2023-05-22', remove_with: '16.0'
    #   end
    class IgnoredColumns < RuboCop::Cop::Base
      USE_CONCERN_ADD_MSG = 'Use `IgnorableColumns` concern instead of adding to `self.ignored_columns`.'
      USE_CONCERN_SET_MSG = 'Use `IgnorableColumns` concern instead of setting `self.ignored_columns`.'
      WRONG_MODEL_MSG = <<~MSG
        If the model exists in CE and EE, the column has to be ignored
        in the CE model. If the model only exists in EE, then it has to be added there.
      MSG

      RESTRICT_ON_SEND = %i[ignored_columns ignored_columns= ignore_column ignore_columns].freeze

      def_node_matcher :ignored_columns_add?, <<~PATTERN
        (send (self) :ignored_columns)
      PATTERN

      def_node_matcher :ignored_columns_set?, <<~PATTERN
        (send (self) :ignored_columns= ...)
      PATTERN

      def_node_matcher :using_ignore_columns?, <<~PATTERN
        (send nil? {:ignore_columns :ignore_column}...)
      PATTERN

      def on_send(node)
        if ignored_columns_add?(node)
          add_offense(node.loc.selector, message: USE_CONCERN_ADD_MSG)
        end

        if ignored_columns_set?(node)
          add_offense(node.loc.selector, message: USE_CONCERN_SET_MSG)
        end

        if using_ignore_columns?(node) && used_in_wrong_model?
          add_offense(node, message: WRONG_MODEL_MSG)
        end
      end

      private

      def used_in_wrong_model?
        file_path = processed_source.file_path

        ee_model?(file_path) && ce_model_exists?(file_path)
      end

      def ee_model?(path)
        path.include?(ee_directory)
      end

      def ee_directory
        File.join(rails_root, 'ee')
      end

      def rails_root
        File.expand_path('../..', __dir__)
      end

      def ce_model_exists?(path)
        File.exist?(path.gsub(%r{/ee/}, '/'))
      end
    end
  end
end
