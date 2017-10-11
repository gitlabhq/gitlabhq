module QA
  module Scenario
    ##
    # Run test suite against any Gitlab instance,
    # including staging and on-premises installation.
    #
    class Entrypoint < Template
      def perform(address, *files)
        Specs::Config.perform do |specs|
          specs.address = address
          configure_specs(specs)
        end

        ##
        # Perform before hooks, which are different for CE and EE
        #
        Runtime::Release.perform_before_hooks

        Specs::Runner.perform do |specs|
          specs.rspec('--tty', files.any? ? files : 'qa/specs/features')
        end
      end

      protected

      def configure_specs(specs) end
    end
  end
end
