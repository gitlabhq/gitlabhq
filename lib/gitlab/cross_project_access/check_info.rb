module Gitlab
  class CrossProjectAccess
    class CheckInfo
      attr_accessor :actions, :positive_condition, :negative_condition, :skip

      def initialize(actions, positive_condition, negative_condition, skip)
        @actions = actions
        @positive_condition = positive_condition
        @negative_condition = negative_condition
        @skip = skip
      end

      def should_skip?(object)
        return !should_run?(object) unless @skip

        skip_for_action = @actions[current_action(object)]
        skip_for_action = false if @actions[current_action(object)].nil?

        # We need to do the opposite of what was defined in the following cases:
        # - skip_cross_project_access_check index: true, if: -> { false }
        # - skip_cross_project_access_check index: true, unless: -> { true }
        if positive_condition_is_false?(object)
          skip_for_action = !skip_for_action
        end

        if negative_condition_is_true?(object)
          skip_for_action = !skip_for_action
        end

        skip_for_action
      end

      def should_run?(object)
        return !should_skip?(object) if @skip

        run_for_action = @actions[current_action(object)]
        run_for_action = true if @actions[current_action(object)].nil?

        # We need to do the opposite of what was defined in the following cases:
        # - requires_cross_project_access index: true, if: -> { false }
        # - requires_cross_project_access index: true, unless: -> { true }
        if positive_condition_is_false?(object)
          run_for_action = !run_for_action
        end

        if negative_condition_is_true?(object)
          run_for_action = !run_for_action
        end

        run_for_action
      end

      def positive_condition_is_false?(object)
        @positive_condition && !object.instance_exec(&@positive_condition)
      end

      def negative_condition_is_true?(object)
        @negative_condition && object.instance_exec(&@negative_condition)
      end

      def current_action(object)
        object.respond_to?(:action_name) ? object.action_name.to_sym : nil
      end
    end
  end
end
