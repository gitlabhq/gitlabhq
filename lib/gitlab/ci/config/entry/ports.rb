# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of the ports of a Docker service.
        #
        class Ports < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, type: Array
            validates :config, port_name_present_and_unique: true
            validates :config, port_unique: true
          end

          def compose!(deps = nil)
            super do
              @entries = []
              @config.each do |config|
                @entries << ::Gitlab::Config::Entry::Factory.new(Entry::Port)
                  .value(config || {})
                  .with(key: "port", parent: self, description: "port definition.") # rubocop:disable CodeReuse/ActiveRecord
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
