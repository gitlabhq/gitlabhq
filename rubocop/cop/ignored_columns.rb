# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that blacklists the usage of `ActiveRecord::Base.ignored_columns=` directly
    class IgnoredColumns < RuboCop::Cop::Base
      USE_CONCERN_MSG = 'Use `IgnoredColumns` concern instead of adding to `self.ignored_columns`.'
      WRONG_MODEL_MSG = 'If the model exists in CE and EE, the column has to be ignored ' \
        'in the CE model. If the model only exists in EE, then it has to be added there.'

      def_node_matcher :ignored_columns?, <<~PATTERN
        (send (self) :ignored_columns)
      PATTERN

      def_node_matcher :ignore_columns?, <<~PATTERN
        (send nil? :ignore_columns ...)
      PATTERN

      def_node_matcher :ignore_column?, <<~PATTERN
        (send nil? :ignore_column ...)
      PATTERN

      def on_send(node)
        if ignored_columns?(node)
          add_offense(node, message: USE_CONCERN_MSG)
        end

        if using_ignore?(node) && used_in_wrong_model?
          add_offense(node, message: WRONG_MODEL_MSG)
        end
      end

      private

      def using_ignore?(node)
        ignore_columns?(node) || ignore_column?(node)
      end

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
