# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker service.
        #
        class Service < Image
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_KEYS = %i[name entrypoint command alias ports].freeze

          validations do
            validates :config, hash_or_string: true
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :config, disallowed_keys: %i[ports], unless: :with_image_ports?

            validates :name, type: String, presence: true
            validates :entrypoint, array_of_strings: true, allow_nil: true
            validates :command, array_of_strings: true, allow_nil: true
            validates :alias, type: String, allow_nil: true
            validates :alias, type: String, presence: true, unless: ->(record) { record.ports.blank? }
          end

          entry :ports, Entry::Ports,
            description: 'Ports used to expose the service'

          def alias
            value[:alias]
          end

          def command
            value[:command]
          end
        end
      end
    end
  end
end
