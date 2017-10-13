module QA
  module Scenario
    ##
    # Run test suite against any GitLab instance,
    # including staging and on-premises installation.
    #
    class Entrypoint < Template
      def self.tags(*tags)
        @tags = tags
      end

      def self.tag_switches
        @tags.map { |tag| ['-t', tag.to_s] }
      end

      def perform(address, *files)
        Specs::Config.perform do |specs|
          specs.address = address
        end

        ##
        # Perform before hooks, which are different for CE and EE
        #
        Runtime::Release.perform_before_hooks

        Specs::Runner.perform do |specs|
          specs.rspec('--tty', self.class.tag_switches, files.any? ? files : 'qa/specs/features')
        end
      end
    end
  end
end
