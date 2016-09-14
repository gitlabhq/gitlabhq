module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents an environment.
        #
        class Environment < Entry
          include Validatable

          validations do
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
            case
            when string? then @config
            when hash? then @config[:name]
            end
          end

          def url
            @config[:url] if hash?
          end

          def value
            case
            when string? then { name: @config }
            when hash? then @config
            end
          end
        end
      end
    end
  end
end
