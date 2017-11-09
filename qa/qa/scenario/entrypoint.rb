module QA
  module Scenario
    ##
    # Base class for running the suite against any GitLab instance,
    # including staging and on-premises installation.
    #
    class Entrypoint < Template
      include Bootable

      def self.tags(*tags)
        @tags = tags
      end

      def self.get_tags
        @tags
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
          specs.rspec(
            tty: true,
            tags: self.class.get_tags,
            files: files.any? ? files : 'qa/specs/features'
          )
        end
      end
    end
  end
end
