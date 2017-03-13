module QA
  module EE
    module Strategy
      extend self
      def extend_autoloads!
        require 'qa/ee'
      end

      def perform_before_hooks
        EE::Scenario::License::Add.perform
      end
    end
  end
end
