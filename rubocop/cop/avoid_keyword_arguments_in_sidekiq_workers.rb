# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that blacklists keyword arguments usage in Sidekiq workers
    class AvoidKeywordArgumentsInSidekiqWorkers < RuboCop::Cop::Cop
      MSG = "Do not use keyword arguments in Sidekiq workers. " \
        "For details, check https://github.com/mperham/sidekiq/issues/2372"
      OBSERVED_METHOD = :perform

      def on_def(node)
        return if node.method_name != OBSERVED_METHOD

        node.arguments.each do |argument|
          if argument.type == :kwarg || argument.type == :kwoptarg
            add_offense(node, location: :expression)
          end
        end
      end
    end
  end
end
