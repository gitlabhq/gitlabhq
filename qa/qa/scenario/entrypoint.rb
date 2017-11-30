module QA
  module Scenario
    ##
    # Base class for running the suite against any GitLab instance,
    # including staging and on-premises installation.
    #
    class Entrypoint < Template
      include Bootable

      def perform(address, *files)
        Specs::Config.act { configure_capybara! }
        Runtime::Scenario.define(:gitlab_address, address)

        ##
        # Perform before hooks, which are different for CE and EE
        #
        Runtime::Release.perform_before_hooks

        Specs::Runner.perform do |specs|
          specs.tty = true
          specs.tags = self.class.get_tags
          specs.files = files.any? ? files : 'qa/specs/features'
        end
      end

      def self.tags(*tags)
        @tags = tags
      end

      def self.get_tags
        @tags
      end
    end
  end
end
