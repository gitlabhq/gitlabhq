# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Collection
        class Item
          include Gitlab::Utils::StrongMemoize

          VARIABLES_REGEXP = /\$\$|%%|\$(?<key>[a-zA-Z_][a-zA-Z0-9_]*)|\${\g<key>?}|%\g<key>%/
          VARIABLE_REF_CHARS = %w[$ %].freeze

          def initialize(key:, value:, public: true, file: false, masked: false, raw: false)
            raise ArgumentError, "`#{key}` must be of type String or nil value, while it was: #{value.class}" unless
              value.is_a?(String) || value.nil?

            @variable = { key: key, value: value, public: public, file: file, masked: masked, raw: raw }
          end

          def key
            @variable.fetch(:key)
          end

          def value
            @variable.fetch(:value)
          end

          def raw?
            @variable.fetch(:raw)
          end
          alias_method :raw, :raw?

          def file?
            @variable.fetch(:file)
          end

          def masked?
            @variable.fetch(:masked)
          end

          def [](key)
            @variable.fetch(key)
          end

          def ==(other)
            to_runner_variable == self.class.fabricate(other).to_runner_variable
          end

          def depends_on
            strong_memoize(:depends_on) do
              next if raw?

              next unless self.class.possible_var_reference?(value)

              value.scan(VARIABLES_REGEXP).filter_map(&:last)
            end
          end

          ##
          # If `file: true` or `raw: true` has been provided we expose it, otherwise we
          # don't expose `file` and `raw` attributes at all (stems from what the runner expects).
          #
          # This method should only be called via runner_variables->to_runner_variables->to_runner_variable
          # because this is an expensive operation by initializing a new object.
          ##
          def to_runner_variable
            @variable.reject do |hash_key, hash_value|
              (hash_key == :file || hash_key == :raw) && hash_value == false
            end
          end

          def to_hash_variable
            @variable
          end

          def self.fabricate(resource)
            case resource
            when Hash
              self.new(**resource.symbolize_keys)
            when ::Ci::HasVariable
              self.new(**resource.to_hash_variable)
            when self
              resource.dup
            else
              raise ArgumentError, "Unknown `#{resource.class}` variable resource!"
            end
          end

          def self.possible_var_reference?(value)
            return unless value

            VARIABLE_REF_CHARS.any? { |symbol| value.include?(symbol) }
          end

          # This is for debugging purposes only.
          def to_s
            return to_hash_variable.to_s unless depends_on

            "#{to_hash_variable}, depends_on=#{depends_on}"
          end
        end
      end
    end
  end
end
