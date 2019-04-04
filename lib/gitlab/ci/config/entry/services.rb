# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker services.
        #
        class Services < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: Array
            validates :config, services_with_ports_alias_unique: true, if: ->(record) { record.opt(:with_image_ports) }
          end

          def compose!(deps = nil)
            super do
              @entries = []
              @config.each do |config|
                @entries << ::Gitlab::Config::Entry::Factory.new(Entry::Service)
                  .value(config || {})
                  .with(key: "service", parent: self, description: "service definition.") # rubocop:disable CodeReuse/ActiveRecord
                  .create!
              end

              @entries.each do |entry|
                entry.compose!(deps)
              end
            end
          end

          def value
            @entries.map(&:value)
          end

          def descendants
            @entries
          end
        end
      end
    end
  end
end
