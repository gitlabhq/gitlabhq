# frozen_string_literal: true

module WorkItems
  module Widgets
    class CurrentUserTodos < Base
      def self.quick_action_commands
        [:todo, :done]
      end

      def self.quick_action_params
        [:todo_event]
      end

      def self.process_quick_action_param(param_name, value)
        return super unless param_name == :todo_event

        { action: value == 'done' ? 'mark_as_done' : 'add' }
      end
    end
  end
end
