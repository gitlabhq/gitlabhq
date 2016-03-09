# The spinach-rerun-reporter doesn't define the on_undefined_step
# See it here: https://github.com/javierav/spinach-rerun-reporter/blob/master/lib/spinach/reporter/rerun.rb
module Spinach
  class Reporter
    class Rerun
      def on_undefined_step(step_data, failure, step_definitions = nil)
        super step_data, failure, step_definitions

        # save feature file and scenario line
        @rerun << "#{current_feature.filename}:#{current_scenario.line}"
      end
    end
  end
end
