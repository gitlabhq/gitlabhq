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
            validates :alias, type: String, allow_nil: true
            validates :alias, type: String, presence: true, unless: ->(record) { record.ports.blank? }
          end

          entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
            description: 'Environment variables available for this service.',
            inherit: false

          attributes :variables

          entry :command, Entry::Commands,
            description: 'Commands that will be executed in the service.',
            inherit: false

          def alias
            value[:alias]
          end

          def command
            command_value if command_defined?
          end

          def value
            if hash?
              super.merge(
                command: (command_value if command_defined?),
                alias: @config[:alias],
                variables: (variables_value if variables_defined?)
              ).compact
            else
              super
            end
          end
        end
      end
    end
  end
end
