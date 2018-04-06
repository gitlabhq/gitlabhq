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
          attribute :geo_skip_setup?, '--without-setup'

          def perform(options, *files)
            unless options[:geo_skip_setup?]
              Geo::Primary.act do
                add_license
                enable_hashed_storage
                set_replication_password
                set_primary_node
                add_secondary_node
              end

              Geo::Secondary.act { replicate_database }
            end

            Specs::Runner.perform do |specs|
              specs.tty = true
              specs.tags = %w[geo]
            end
          end

          class Primary
            include QA::Scenario::Actable

            def initialize
              @address = QA::Runtime::Scenario.geo_primary_address
              @name = QA::Runtime::Scenario.geo_primary_name
            end

            def add_license
              puts 'Adding GitLab EE license ...'

              QA::Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
                Factory::License.fabricate!(ENV['EE_LICENSE'])
              end
            end

            def enable_hashed_storage
              puts 'Enabling hashed repository storage setting ...'

              QA::Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
                QA::Factory::Settings::HashedStorage.fabricate!(:enabled)
              end
            end

            def add_secondary_node
              puts 'Adding new Geo secondary node ...'

              QA::Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
                Factory::Geo::Node.fabricate! do |node|
                  node.address = QA::Runtime::Scenario.geo_secondary_address
                end
              end
            end

            def set_replication_password
              puts 'Setting replication password on primary node ...'

              QA::Service::Omnibus.new(@name).act do
                gitlab_ctl 'set-replication-password', input: 'echo mypass'
              end
            end

            def set_primary_node
              puts 'Making this node a primary node  ...'

              QA::Service::Omnibus.new(@name).act do
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
              puts 'Starting Geo replication on secondary node ...'

              QA::Service::Omnibus.new(@name).act do
                require 'uri'

                host = URI(QA::Runtime::Scenario.geo_primary_address).host
                slot = QA::Runtime::Scenario.geo_primary_name.tr('-', '_')

                gitlab_ctl "replicate-geo-database --host=#{host} --slot-name=#{slot} " \
                           "--sslmode=disable --no-wait --force", input: 'echo mypass'
              end

              puts 'Waiting until secondary node services are restarted ...'

              sleep 60 # Wait until services are restarted correctly
            end
          end
        end
      end
    end
  end
end
