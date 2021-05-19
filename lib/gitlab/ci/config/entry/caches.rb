# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents caches configuration
        #
        class Caches < ::Gitlab::Config::Entry::ComposableArray
          include ::Gitlab::Config::Entry::Validatable

          MULTIPLE_CACHE_LIMIT = 4

          validations do
            validate do
              unless config.is_a?(Hash) || config.is_a?(Array)
                errors.add(:config, 'can only be a Hash or an Array')
              end

              if config.is_a?(Array) && config.count > MULTIPLE_CACHE_LIMIT
                errors.add(:config, "no more than #{MULTIPLE_CACHE_LIMIT} caches can be created")
              end
            end
          end

          def initialize(*args)
            super

            @key = nil
          end

          def composable_class
            Entry::Cache
          end
        end
      end
    end
  end
end
