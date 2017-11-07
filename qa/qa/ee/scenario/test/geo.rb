module QA
  module EE
    module Scenario
      module Test
        class Geo < QA::Scenario::Entrypoint
          # TODO, https://gitlab.com/gitlab-org/gitlab-qa/issues/85
          #
          def perform(primary_address, primary_name, secondary_address, secondary_name)
            Geo::Primary.act do
              add_license
              enable_hashed_storage
              set_replication_password
              set_primary_node
            end

            Geo::Secondary.act { replicate_database }

            Geo::Primary.act do
              add_secondary_node
              test_features
            end

            Geo::Secondary.act { test_backfilling }
          end

          private

          class Primary
            include QA::Scenario::Actable

            def initialize
              @address = QA::Runtime::Scenario.primary_address
              @name = QA::Runtime::Scenario.primary_name

              Specs::Config.perform do |specs|
                specs.address = @address
              end
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
              Shell::Omnibus.act do
                gitlab_ctl 'set-replication-password', input: 'echo mypass'
              end
            end

            def set_primary_node
              Shell::Omnibus.act do
                gitlab_ctl 'set-geo-primary-node'
              end
            end

            def test_features
              Specs::Runner.perform do |specs|
                specs.rspec(tty: true, tags: %w[core])
              end
            end
          end

          class Secondary
            include QA::Scenario::Actable

            def initialize
              @address = QA::Runtime::Scenario.secondary_address
              @name = QA::Runtime::Scenario.secondary_name
              @slot = @address.gsub(/\.|-/, '_')

              Specs::Config.perform do |specs|
                specs.address = @address
              end
            end

            def replicate_database
              Shell::Omnibus.act do
                gitlab_ctl "replicate-geo-database --host=#{@address} --slot-name=#{@slot} --no-wait", input: 'echo mypass'
              end
            end

            def test_backfilling
              Specs::Runner.perform do |specs|
                specs.rspec(tty: true, tags: %w[geo secondary])
              end
            end
          end
        end
      end
    end
  end
end
