# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # This cop identifies direct calls to hard delete classes that could lead to data loss.
      class HardDeleteCalls < RuboCop::Cop::Base
        MSG = 'Avoid the use of `%{observed_class}`. Use `%{preferred_class}` instead. ' \
          'See https://docs.gitlab.com/development/deleting_data/ '

        HARD_DELETE_CLASSES = {
          'Projects::DestroyService' => 'Projects::MarkForDeletionService',
          'ProjectDestroyWorker' => 'Projects::MarkForDeletionService',
          'Groups::DestroyService' => 'Groups::MarkForDeletionService',
          'GroupDestroyWorker' => 'Groups::MarkForDeletionService'
        }.freeze

        def on_send(node)
          check_node(node)
        end

        def on_csend(node)
          check_node(node)
        end

        private

        def check_node(node)
          receiver = node.receiver

          return unless receiver && receiver.const_type?

          preferred_class = HARD_DELETE_CLASSES[receiver.const_name]

          return unless preferred_class

          add_offense(node, message: message(receiver.const_name, preferred_class))
        end

        def message(observed_class, preferred_class)
          format(MSG, observed_class: observed_class, preferred_class: preferred_class)
        end
      end
    end
  end
end
