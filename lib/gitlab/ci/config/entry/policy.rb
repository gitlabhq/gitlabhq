# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Base class for OnlyPolicy and ExceptPolicy
        #
        class Policy < ::Gitlab::Config::Entry::Simplifiable
          class RefsPolicy < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, array_of_strings_or_regexps: true
            end

            def value
              { refs: @config }
            end
          end

          class ComplexPolicy < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[refs kubernetes variables changes].freeze
            attributes :refs, :kubernetes, :variables, :changes

            validations do
              validates :config, presence: true
              validates :config, allowed_keys: ALLOWED_KEYS
              validate :variables_expressions_syntax

              with_options allow_nil: true do
                validates :refs, array_of_strings_or_regexps: true
                validates :kubernetes, allowed_values: %w[active]
                validates :variables, array_of_strings: true
                validates :changes, array_of_strings: true
              end

              def variables_expressions_syntax
                return unless variables.is_a?(Array)

                statements = variables.map do |statement|
                  ::Gitlab::Ci::Pipeline::Expression::Statement.new(statement)
                end

                statements.each do |statement|
                  unless statement.valid?
                    errors.add(:variables, "Invalid expression syntax")
                  end
                end
              end
            end
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
            def errors
              ["#{location} has to be either an array of conditions or a hash"]
            end
          end

          def self.default
          end

          ##
          # Class-level execution won't be inherited by subclasses by default.
          # Therefore, we need to explicitly execute that for OnlyPolicy and ExceptPolicy
          def self.inherited(klass)
            super

            klass.strategy :RefsPolicy, if: -> (config) { config.is_a?(Array) }
            klass.strategy :ComplexPolicy, if: -> (config) { config.is_a?(Hash) }
          end
        end
      end
    end
  end
end
