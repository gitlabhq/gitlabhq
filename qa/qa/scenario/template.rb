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
          specs.options =
            if rspec_options.any?
              rspec_options
            else
              ['--tag', self.class.focus.join(','), '--', ::File.expand_path('../specs/features', __dir__)]
            end
        end
      end
    end
  end
end
