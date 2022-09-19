# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker service.
        #
        class Service < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Imageable

          ALLOWED_KEYS = %i[command alias variables].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS + IMAGEABLE_ALLOWED_KEYS
            validates :command, array_of_strings: true, allow_nil: true
            validates :alias, type: String, allow_nil: true
            validates :alias, type: String, presence: true, unless: ->(record) { record.ports.blank? }
          end

          entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
            description: 'Environment variables available for this service.',
            inherit: false

          attributes :variables

          def alias
            value[:alias]
          end

          def command
            value[:command]
          end

          def value
            if string?
              { name: @config }
            elsif hash?
              @config.merge(
                pull_policy: pull_policy_value
              ).compact
            else
              {}
            end
          end
        end
      end
    end
  end
end
