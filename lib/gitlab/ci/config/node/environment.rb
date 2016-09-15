module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents an environment.
        #
        class Environment < Entry
          include Validatable

          ALLOWED_KEYS = %i[name url]

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS, if: :hash?

            validates :name, presence: true

            validates :url,
                      length: { maximum: 255 },
                      allow_nil: true,
                      addressable_url: true

            validate do
              unless hash? || string?
                errors.add(:config, 'should be a hash or a string')
              end
            end
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

          def url
            value[:url]
          end

          def value
            case @config.type
            when String then { name: @config }
            when Hash then @config
            end
          end
        end
      end
    end
  end
end
