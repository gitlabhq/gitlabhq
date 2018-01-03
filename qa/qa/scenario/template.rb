module QA
  module Scenario
    class Template
      def self.perform(*args)
        new.tap do |scenario|
          yield scenario if block_given?
          return scenario.perform(*args)
        end
      end

      def perform(*_args)
        raise NotImplementedError
      end
    end
  end
end
