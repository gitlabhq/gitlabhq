# frozen_string_literal: true

module Keeps
  module Helpers
    # Regenerates the `.rubocop_todo` files via the `rubocop:todo:generate` rake task so that offenses which were
    # automatically fixed over time are not reintroduced.
    class RubocopTodoGenerator
      def generate
        Gitlab::Application.load_tasks
        Rake::Task["rubocop:todo:generate"].invoke
      end
    end
  end
end
