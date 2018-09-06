module QA
  module Scenario
    class Template
      class << self
        def perform(*args)
          new.tap do |scenario|
            yield scenario if block_given?
            break scenario.perform(*args)
          end
        end

        def tags(*tags)
          @tags = tags
        end

        def focus
          @tags.to_a
        end
      end

      def perform(address, *rspec_options)
        Runtime::Scenario.define(:gitlab_address, address)

        ##
        # Perform before hooks, which are different for CE and EE
        #
        Runtime::Release.perform_before_hooks

        Specs::Runner.perform do |specs|
          specs.tty = true
          specs.tags = self.class.focus
          specs.options = rspec_options if rspec_options.any?
        end
      end
    end
  end
end
