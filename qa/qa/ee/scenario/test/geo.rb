module QA
  module EE
    module Scenario
      module Test
        class Geo < QA::Scenario::Template
          include QA::Scenario::Bootable

          attribute :geo_primary_address, '--primary-address PRIMARY'
          attribute :geo_primary_name, '--primary-name PRIMARY_NAME'
          attribute :geo_secondary_address, '--secondary-address SECONDARY'
          attribute :geo_secondary_name, '--secondary-name SECONDARY_NAME'

          def perform(**args)
            # TODO, abstract this away in the Factory module
            QA::Specs::Config.act { configure_capybara! }

            # TODO, devise a way to decouple licence factory from Runtime.gitlab_address
            QA::Runtime::Scenario.define(:gitlab_address, args[:geo_primary_address])

            Geo::Primary.act do
              add_license
              enable_hashed_storage
              set_replication_password
              set_primary_node
            end

            Geo::Secondary.act { replicate_database }
            Geo::Primary.act { add_secondary_node }

            # Execute RSpec :geo suite
            #
            # Specs::Runner.perform do |specs|
            #   specs.rspec(tty: true, tags: %w[core])
            # end
          end

          private

          class Primary
            include QA::Scenario::Actable

            def initialize
              @address = QA::Runtime::Scenario.geo_primary_address
              @name = QA::Runtime::Scenario.geo_primary_name
            end

            def add_license
              # TODO move ENV call to the scenario
              #
              Scenario::License::Add.perform(ENV['EE_LICENSE'])
            end

            def enable_hashed_storage
              # TODO implement hashed storage factory
            end

            def add_secondary_node
              # TODO implement secondary node factory
            end

            def set_replication_password
              QA::Shell::Omnibus.new(@name).act do
                gitlab_ctl 'set-replication-password', input: 'echo mypass'
              end
            end

            def set_primary_node
              Shell::Omnibus.new(@name).act do
                gitlab_ctl 'set-geo-primary-node'
              end
            end
          end

          class Secondary
            include QA::Scenario::Actable

            def initialize
              @address = QA::Runtime::Scenario.geo_secondary_address
              @name = QA::Runtime::Scenario.geo_secondary_name
            end

            def replicate_database
              Shell::Omnibus.new(@name).act do
                gitlab_ctl "replicate-geo-database --host=#{@address} --slot-name=#{@name} --no-wait", input: 'echo mypass'
              end
            end
          end
        end
      end
    end
  end
end
