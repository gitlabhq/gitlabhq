# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents the configuration for passing attributes to the downstream pipeline
        #
        class Trigger
          class Forward < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[yaml_variables pipeline_variables].freeze

            attributes ALLOWED_KEYS

            validations do
              validates :config, allowed_keys: ALLOWED_KEYS

              with_options allow_nil: true do
                validates :yaml_variables, boolean: true
                validates :pipeline_variables, boolean: true
              end
            end
          end
        end
      end
    end
  end
end
