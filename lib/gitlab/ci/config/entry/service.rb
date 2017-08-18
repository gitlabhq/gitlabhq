module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker service.
        #
        class Service < Image
          include Validatable

          ALLOWED_KEYS = %i[name entrypoint command alias].freeze

          validations do
            validates :config, hash_or_string: true
            validates :config, allowed_keys: ALLOWED_KEYS

            validates :name, type: String, presence: true
            validates :entrypoint, array_of_strings: true, allow_nil: true
            validates :command, array_of_strings: true, allow_nil: true
            validates :alias, type: String, allow_nil: true
          end

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
