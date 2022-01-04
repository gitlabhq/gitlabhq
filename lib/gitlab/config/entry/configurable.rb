# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # This mixin is responsible for adding DSL, which purpose is to
      # simplify the process of adding child nodes.
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
            return {} unless @nodes

            @nodes.transform_values(&:dup)
          end

          def reserved_node_names
            self.nodes.select do |_, node|
              node.reserved?
            end.keys
          end

          private

          # rubocop: disable CodeReuse/ActiveRecord
          def entry(key, entry, description: nil, default: nil, inherit: nil, reserved: nil, deprecation: nil, metadata: {})
            entry_name = key.to_sym
            raise ArgumentError, "Entry '#{key}' already defined in '#{name}'" if @nodes.to_h[entry_name]

            factory = ::Gitlab::Config::Entry::Factory.new(entry)
              .with(description: description)
              .with(default: default)
              .with(inherit: inherit)
              .with(reserved: reserved)
              .with(deprecation: deprecation)
              .metadata(metadata)

            @nodes ||= {}
            @nodes[entry_name] = factory

            helpers(entry_name)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def dynamic_helpers(*nodes)
            helpers(*nodes, dynamic: true)
          end

          def helpers(*nodes, dynamic: false)
            nodes.each do |symbol|
              if method_defined?("#{symbol}_defined?") || method_defined?("#{symbol}_entry") || method_defined?("#{symbol}_value")
                raise ArgumentError, "Method '#{symbol}_defined?', '#{symbol}_entry' or '#{symbol}_value' already defined in '#{name}'"
              end

              unless @nodes.to_h[symbol]
                raise ArgumentError, "Entry for #{symbol} is undefined" unless dynamic
              end

              define_method("#{symbol}_defined?") do
                entries[symbol]&.specified?
              end

              define_method("#{symbol}_entry") do
                entries[symbol]
              end

              define_method("#{symbol}_value") do
                entry = entries[symbol]
                entry.value if entry&.valid?
              end
            end
          end
        end
      end
    end
  end
end
