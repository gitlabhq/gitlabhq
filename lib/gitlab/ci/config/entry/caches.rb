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

          validations do
            validate do
              unless config.is_a?(Hash) || config.is_a?(Array)
                errors.add(:config, 'can only be a Hash or an Array')
              end

              limit = ::Gitlab::CurrentSettings.ci_max_caches_per_job

              if config.is_a?(Array) && config.count > limit
                errors.add(:config, "no more than #{limit} caches can be created")
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
