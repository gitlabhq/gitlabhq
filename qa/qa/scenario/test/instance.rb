# frozen_string_literal: true

module QA
  module Scenario
    module Test
      # This class exists for back-compatibility so that gitlab-qa can continue
      # to call Test::Instance instead of Test::Instance::All until at least
      # the current latest GitLab version has the Test::Instance::All class.
      # As of Aug, 22nd 2018. Only GitLab >= 11.3 has this class.
      module Instance
        include Bootable

        def self.perform(*args)
          self.tap do |scenario|
            yield scenario if block_given?
            break scenario.do_perform(*args)
          end
        end

        def self.do_perform(address, *rspec_options)
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
                ['--tag', self.class.focus.join(','), '--', ::File.expand_path('../../specs/features', __dir__)]
              end
          end
        end
      end
    end
  end
end
