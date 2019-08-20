# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Rules < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, presence: true
            validates :config, type: Array
          end

          def compose!(deps = nil)
            super(deps) do
              @config.each_with_index do |rule, index|
                @entries[index] = ::Gitlab::Config::Entry::Factory.new(Entry::Rules::Rule)
                  .value(rule)
                  .with(key: "rule", parent: self, description: "rule definition.") # rubocop:disable CodeReuse/ActiveRecord
                  .create!
              end

              @entries.each_value do |entry|
                entry.compose!(deps)
              end
            end
          end
        end
      end
    end
  end
end
