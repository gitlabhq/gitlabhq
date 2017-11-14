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
            # TODO, Factory::License -> gitlab-org/gitlab-qa#86
            #
            QA::Specs::Config.act { configure_capybara! }
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
              # TODO EE license to Runtime.license, gitlab-org/gitlab-qa#86
              #
              Scenario::License::Add.perform(ENV['EE_LICENSE'])
            end

            def enable_hashed_storage
              # TODO, Factory::HashedStorage - gitlab-org/gitlab-qa#86
              #
              QA::Scenario::Gitlab::Admin::HashedStorage.perform(:enabled)
            end

            def add_secondary_node
              # TODO, Factory::Geo::Node - gitlab-org/gitlab-qa#86
              #
              Scenario::Geo::Node.perform do |node|
                node.address = QA::Runtime::Scenario.geo_secondary_address
              end
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
              @name = QA::Runtime::Scenario.geo_secondary_name
            end

            def replicate_database
              Shell::Omnibus.new(@name).act do
                require 'uri'

                host = URI(QA::Runtime::Scenario.geo_primary_address).host
                slot = QA::Runtime::Scenario.geo_primary_name.tr('-', '_')

                gitlab_ctl "replicate-geo-database --host=#{host} --slot-name=#{slot} " \
                           "--sslmode=disable --no-wait", input: 'echo mypass'
              end
            end
          end
        end
      end
    end
  end
end
