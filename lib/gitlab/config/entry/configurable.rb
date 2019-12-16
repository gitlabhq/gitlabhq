# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # This mixin is responsible for adding DSL, which purpose is to
      # simplifly process of adding child nodes.
      #
      # This can be used only if parent node is a configuration entry that
      # holds a hash as a configuration value, for example:
      #
      # job:
      #   script: ...
      #   artifacts: ...
      #
      module Configurable
        extend ActiveSupport::Concern

        included do
          include Validatable

          validations do
            validates :config, type: Hash, unless: :skip_config_hash_validation?
          end
        end

        def compose!(deps = nil)
          return unless valid?

          super do
            self.class.nodes.each do |key, factory|
              # If we override the config type validation
              # we can end with different config types like String
              next unless config.is_a?(Hash)

              entry_create!(key, config[key])
            end

            yield if block_given?

            entries.each_value do |entry|
              entry.compose!(deps)
            end
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def entry_create!(key, value)
          factory = self.class
            .nodes[key]
            .value(value)
            .with(key: key, parent: self)

          entries[key] = factory.create!
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def skip_config_hash_validation?
          false
        end

        class_methods do
          def nodes
            Hash[(@nodes || {}).map { |key, factory| [key, factory.dup] }]
          end

          def reserved_node_names
            self.nodes.select do |_, node|
              node.reserved?
            end.keys
          end

          private

          # rubocop: disable CodeReuse/ActiveRecord
          def entry(key, entry, description: nil, default: nil, inherit: nil, reserved: nil, metadata: {})
            factory = ::Gitlab::Config::Entry::Factory.new(entry)
              .with(description: description)
              .with(default: default)
              .with(inherit: inherit)
              .with(reserved: reserved)
              .metadata(metadata)

            (@nodes ||= {}).merge!(key.to_sym => factory)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def helpers(*nodes)
            nodes.each do |symbol|
              define_method("#{symbol}_defined?") do
                entries[symbol]&.specified?
              end

              define_method("#{symbol}_value") do
                return unless entries[symbol] && entries[symbol].valid?

                entries[symbol].value
              end
            end
          end
        end
      end
    end
  end
end
