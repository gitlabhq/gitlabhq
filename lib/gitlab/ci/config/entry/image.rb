module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a Docker image.
        #
        class Image < Node
          include Validatable

          ALLOWED_KEYS = %i[name entrypoint].freeze

          validations do
            validates :config, hash_or_string: true
            validates :config, allowed_keys: ALLOWED_KEYS

            validates :name, type: String, presence: true
            validates :entrypoint, array_of_strings: true, allow_nil: true
          end

          def hash?
            @config.is_a?(Hash)
          end

          def string?
            @config.is_a?(String)
          end

          def name
            value[:name]
          end

          def entrypoint
            value[:entrypoint]
          end

          def value
            return { name: @config } if string?
            return @config if hash?

            {}
          end
        end
      end
    end
  end
end
