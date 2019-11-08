# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a set of needs dependencies.
        #
        class Needs < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, presence: true

            validate do
              unless config.is_a?(Hash) || config.is_a?(Array)
                errors.add(:config, 'can only be a Hash or an Array')
              end
            end

            validate on: :composed do
              extra_keys = value.keys - opt(:allowed_needs)
              if extra_keys.any?
                errors.add(:config, "uses invalid types: #{extra_keys.join(', ')}")
              end
            end
          end

          def compose!(deps = nil)
            super(deps) do
              [@config].flatten.each_with_index do |need, index|
                @entries[index] = ::Gitlab::Config::Entry::Factory.new(Entry::Need)
                  .value(need)
                  .with(key: "need", parent: self, description: "need definition.") # rubocop:disable CodeReuse/ActiveRecord
                  .create!
              end

              @entries.each_value do |entry|
                entry.compose!(deps)
              end
            end
          end

          def value
            values = @entries.values.select(&:type)
            values.group_by(&:type).transform_values do |values|
              values.map(&:value)
            end
          end
        end
      end
    end
  end
end
