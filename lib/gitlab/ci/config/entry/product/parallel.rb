# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a parallel job config.
        #
        module Product
          class Parallel < ::Gitlab::Config::Entry::Simplifiable
            strategy :ParallelBuilds, if: ->(config) { config.is_a?(Numeric) }
            strategy :MatrixBuilds, if: ->(config) { config.is_a?(Hash) }

            PARALLEL_LIMIT = 200

            class ParallelBuilds < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable

              validations do
                validates :config, numericality: { only_integer: true,
                                                   greater_than_or_equal_to: 1,
                                                   less_than_or_equal_to: Entry::Product::Parallel::PARALLEL_LIMIT },
                  allow_nil: true

                validate do
                  next unless opt(:allowed_strategies)
                  next if opt(:allowed_strategies).include?(:numeric)

                  errors.add(:config, 'cannot use "parallel: <number>".')
                end
              end

              def value
                { number: super.to_i }
              end
            end

            class MatrixBuilds < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Attributable
              include ::Gitlab::Config::Entry::Configurable

              PERMITTED_KEYS = %i[matrix].freeze

              validations do
                validates :config, allowed_keys: PERMITTED_KEYS
                validates :config, required_keys: PERMITTED_KEYS

                validate do
                  next unless opt(:allowed_strategies)
                  next if opt(:allowed_strategies).include?(:matrix)

                  errors.add(:config, 'cannot use "parallel: matrix".')
                end
              end

              entry :matrix, Entry::Product::Matrix,
                description: 'Variables definition for matrix builds'
            end

            class UnknownStrategy < ::Gitlab::Config::Entry::Node
              def errors
                ["#{location} should be an integer or a hash"]
              end
            end
          end
        end
      end
    end
  end
end
