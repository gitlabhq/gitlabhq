module Gitlab
  class CrossProjectAccess
    module ClassMethods
      def requires_cross_project_access(*args)
        positive_condition, negative_condition, actions = extract_params(args)

        Gitlab::CrossProjectAccess.add_check(
          self,
          actions: actions,
          positive_condition: positive_condition,
          negative_condition: negative_condition
        )
      end

      def skip_cross_project_access_check(*args)
        positive_condition, negative_condition, actions = extract_params(args)

        Gitlab::CrossProjectAccess.add_check(
          self,
          actions: actions,
          positive_condition: positive_condition,
          negative_condition: negative_condition,
          skip: true
        )
      end

      private

      def extract_params(args)
        actions = {}
        positive_condition = nil
        negative_condition = nil

        args.each do |argument|
          if argument.is_a?(Hash)
            positive_condition = argument.delete(:if)
            negative_condition = argument.delete(:unless)
            actions.merge!(argument)
          else
            actions[argument] = true
          end
        end

        [positive_condition, negative_condition, actions]
      end
    end
  end
end
